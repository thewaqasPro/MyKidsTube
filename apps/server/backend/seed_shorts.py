"""
KidsTube Curated Catalog Seed Wrapper
"""
import logging
from seed_curated_catalog import run_curated_seed

logger = logging.getLogger("seed_shorts")

def run_seed():
    logger.info("Executing curated seed pipeline...")
    return run_curated_seed()

if __name__ == "__main__":
    res = run_seed()
    print(res)
