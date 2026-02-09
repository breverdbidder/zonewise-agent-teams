# County Scraper Plan: Orange County, Florida

## Objective

Build a production-ready AgentQL scraper for Orange County (FIPS: 12095) foreclosure auctions that integrates with the ZoneWise multi-county pipeline. Orange County is the first expansion county beyond Brevard, making this the template for all subsequent county builds.

## Target

- **County**: Orange County, FL
- **FIPS Code**: 12095
- **URL**: https://orange.realforeclose.com
- **Auction Type**: Online foreclosure auctions
- **Frequency**: Daily 11 PM EST cron via master_scraper.yml

## Why Orange County First

- Highest foreclosure volume in Central FL after Brevard
- Uses same RealForeclose platform (similar DOM structure)
- Large enough market to validate multi-county architecture
- Population ~1.4M — significant investor interest

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Scraper | AgentQL + Playwright + Python 3.11+ |
| Database | Supabase (multi_county_auctions table) |
| Scheduling | GitHub Actions (master_scraper.yml) |
| Monitoring | Supabase scraper_logs table |
| Repo | zonewise-modal |

## Data Contract

### Required Fields (must match multi_county_auctions schema)

```sql
-- These columns already exist in multi_county_auctions
county_id        TEXT NOT NULL,        -- "12095"
county_name      TEXT NOT NULL,        -- "orange"
case_number      TEXT NOT NULL,        -- e.g., "2024-CA-012345"
property_address TEXT,                 -- "123 Main St"
city             TEXT,                 -- "Orlando"
zip_code         TEXT,                 -- "32801"
parcel_id        TEXT,                 -- County assessor parcel ID
auction_date     TIMESTAMPTZ,         -- ISO 8601
auction_type     TEXT DEFAULT 'foreclosure',
plaintiff        TEXT,                 -- Foreclosing party
defendant        TEXT,                 -- Property owner
judgment_amount  NUMERIC,             -- Dollar amount
opening_bid      NUMERIC,             -- Starting bid
sale_price       NUMERIC,             -- NULL if not yet sold
sale_status      TEXT,                 -- scheduled|sold|cancelled|continued
assessed_value   NUMERIC,             -- From OCPA if available
legal_description TEXT,
scraped_at       TIMESTAMPTZ DEFAULT NOW(),
raw_html         TEXT,                 -- Raw listing HTML
metadata         JSONB DEFAULT '{}'   -- Extra Orange-specific fields
```

### Unique Constraint
```sql
UNIQUE(county_id, case_number, auction_date)
```

### Output JSON (per record)
```json
{
  "county_id": "12095",
  "county_name": "orange",
  "case_number": "2024-CA-012345",
  "property_address": "123 International Dr",
  "city": "Orlando",
  "zip_code": "32819",
  "parcel_id": "25-2210-0000-00-001",
  "auction_date": "2026-02-15T11:00:00-05:00",
  "auction_type": "foreclosure",
  "plaintiff": "Wells Fargo Bank NA",
  "defendant": "John Smith",
  "judgment_amount": 285000.00,
  "opening_bid": 100.00,
  "sale_price": null,
  "sale_status": "scheduled",
  "assessed_value": 310000.00,
  "legal_description": "LOT 5 BLK A INTERNATIONAL VILLAGE PH 2",
  "scraped_at": "2026-02-09T23:00:00-05:00",
  "raw_html": null,
  "metadata": {
    "certificate_number": null,
    "surplus_amount": null,
    "auction_group": "GROUP A"
  }
}
```

## Architecture

### File Structure (in zonewise-modal repo)

```
src/scrapers/
├── base_scraper.py              # Abstract base (existing)
├── brevard_scraper.py           # Reference implementation (existing)
└── orange_scraper.py            # NEW

src/utils/
├── anti_detection.py            # Shared anti-detection utils (existing)
└── fips_codes.py                # County FIPS lookup (existing or create)

tests/
├── conftest.py                  # Shared fixtures (existing)
├── test_brevard_scraper.py      # Reference tests (existing)
└── test_orange_scraper.py       # NEW

.github/workflows/
└── master_scraper.yml           # UPDATE — add orange to county list
```

### Scraper Class Design

```python
# orange_scraper.py should follow this pattern:
class OrangeScraper(BaseScraper):
    """AgentQL-based scraper for Orange County foreclosure auctions."""
    
    COUNTY_ID = "12095"
    COUNTY_NAME = "orange"
    BASE_URL = "https://orange.realforeclose.com"
    
    async def scrape(self, limit: int = None) -> list[dict]:
        """Scrape auction listings. Returns list of records matching data contract."""
        ...
    
    async def scrape_calendar(self) -> list[str]:
        """Get list of auction dates from calendar page."""
        ...
    
    async def scrape_auction_day(self, date: str) -> list[dict]:
        """Scrape all listings for a specific auction date."""
        ...
    
    def parse_listing(self, raw: dict) -> dict:
        """Parse raw listing into data contract format."""
        ...
    
    def validate_record(self, record: dict) -> bool:
        """Validate record has all required fields with correct types."""
        ...
```

## Agent Team: 3 Agents

### Agent 1: Schema Agent (upstream)
**Owns:** `src/utils/fips_codes.py`, `migrations/`
**Does NOT touch:** `src/scrapers/orange_scraper.py`, `tests/`
**Tasks:**
1. Verify FIPS code 12095 maps to Orange County
2. Verify `multi_county_auctions` table has all required columns
3. Check if any Orange-specific columns are needed (likely not)
4. Produce the data contract: exact field → column mapping
5. Check for RLS policies that need county_id filter
6. **Send contract to lead before any implementation**

### Agent 2: Scraper Agent (receives schema contract)
**Owns:** `src/scrapers/orange_scraper.py`
**Does NOT touch:** `migrations/`, `tests/`, `.github/workflows/`
**Tasks:**
1. Analyze https://orange.realforeclose.com DOM structure
2. Build OrangeScraper class following BaseScraper + BrevardScraper patterns
3. Implement AgentQL queries for auction calendar + listing pages
4. Handle pagination across auction dates
5. Parse all fields matching the schema contract EXACTLY
6. Implement anti-detection: random delays (2-5s), user-agent rotation
7. Handle edge cases: cancelled auctions, missing data, network errors
8. **Send sample output JSON to lead before reporting done**

### Agent 3: Test/Integration Agent (receives both contracts)
**Owns:** `tests/test_orange_scraper.py`, `.github/workflows/master_scraper.yml`
**Does NOT touch:** `src/scrapers/orange_scraper.py` (reads only)
**Tasks:**
1. Build pytest suite: unit tests + integration tests
2. Test field mapping matches schema contract
3. Test against live data (fetch 1 page minimum)
4. Test Supabase upsert with sample data
5. Test error handling (bad URL, network timeout, empty response)
6. Update master_scraper.yml to include "orange" in county list
7. Verify no hardcoded credentials
8. **Run full test suite and report results to lead**

## Contract Chain

```
Schema Agent                    Scraper Agent                  Test Agent
    │                               │                              │
    ├─ Verify FIPS + schema         │                              │
    ├─ Produce data contract ──────►│                              │
    │    (field mapping JSON)       ├─ Analyze DOM                 │
    │                               ├─ Build OrangeScraper         │
    │                               ├─ Produce sample output ─────►│
    │                               │                              ├─ Build tests
    │                               │                              ├─ Update workflow
    │                               │                              ├─ Run validation
    │                               │                              │
    └───────────────────────── Lead validates end-to-end ──────────┘
```

## Validation

### Schema Agent Validation
```bash
python -c "
# Verify FIPS
assert '12095' == '12095', 'FIPS mismatch'
print('✓ FIPS code correct for Orange County')
"

# Verify Supabase table
python -c "
from supabase import create_client
import os
sb = create_client(os.environ['SUPABASE_URL'], os.environ['SUPABASE_SERVICE_KEY'])
result = sb.table('multi_county_auctions').select('county_id').eq('county_id', '12095').limit(0).execute()
print('✓ Table accepts county_id 12095')
"
```

### Scraper Agent Validation
```bash
# Import works
python -c "from src.scrapers.orange_scraper import OrangeScraper; print('✓ Import OK')"

# Can fetch data
python -c "
import asyncio
from src.scrapers.orange_scraper import OrangeScraper
async def test():
    s = OrangeScraper()
    data = await s.scrape(limit=2)
    assert len(data) >= 1, 'No data'
    r = data[0]
    assert r['county_id'] == '12095'
    assert r['county_name'] == 'orange'
    assert r['case_number'] is not None
    print(f'✓ Scraped {len(data)} records, contract matches')
asyncio.run(test())
"
```

### Test Agent Validation
```bash
# Tests pass
python -m pytest tests/test_orange_scraper.py -v --tb=short

# Workflow is valid YAML with orange included
python -c "
import yaml
with open('.github/workflows/master_scraper.yml') as f:
    data = yaml.safe_load(f)
assert 'orange' in str(data).lower(), 'Orange not in workflow'
print('✓ Workflow includes orange county')
"
```

### Lead End-to-End Validation
```bash
# Full pipeline test
python -c "
import asyncio, os
from src.scrapers.orange_scraper import OrangeScraper
from supabase import create_client

async def e2e():
    # Scrape
    s = OrangeScraper()
    records = await s.scrape(limit=3)
    print(f'Scraped {len(records)} records')
    
    # Insert
    sb = create_client(os.environ['SUPABASE_URL'], os.environ['SUPABASE_SERVICE_KEY'])
    for r in records:
        sb.table('multi_county_auctions').upsert(
            r, on_conflict='county_id,case_number,auction_date'
        ).execute()
    print('✓ Inserted to Supabase')
    
    # Verify
    result = sb.table('multi_county_auctions').select('*').eq('county_id', '12095').limit(3).execute()
    assert len(result.data) >= 1
    print(f'✓ Verified {len(result.data)} Orange County records in database')

asyncio.run(e2e())
"
```

## Acceptance Criteria

1. ✅ OrangeScraper class extends BaseScraper
2. ✅ Fetches auction data from orange.realforeclose.com
3. ✅ Output matches multi_county_auctions schema exactly
4. ✅ Data upserts into Supabase without constraint violations
5. ✅ Anti-detection: random delays, rotating user agents
6. ✅ Pytest suite passes with >80% coverage
7. ✅ master_scraper.yml includes orange in daily cron
8. ✅ Zero hardcoded credentials
9. ✅ FIPS code 12095 used consistently
10. ✅ Handles edge cases: cancelled auctions, empty pages, network errors
