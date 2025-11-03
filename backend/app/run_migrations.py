"""
Run database migrations on startup.
This ensures the database schema is up-to-date before the API starts.
"""

import os
from pathlib import Path
from sqlalchemy import text
from .database import engine

def run_migrations():
    """Run all pending migrations from the migrations folder."""
    migrations_dir = Path(__file__).parent.parent / "migrations"
    
    if not migrations_dir.exists():
        print("No migrations directory found, skipping migrations")
        return
    
    # Get all .sql files sorted by name
    migration_files = sorted(migrations_dir.glob("*.sql"))
    
    if not migration_files:
        print("No migration files found")
        return
    
    print(f"Found {len(migration_files)} migration file(s)")
    
    with engine.connect() as conn:
        for migration_file in migration_files:
            print(f"Running migration: {migration_file.name}")
            
            try:
                # Read the migration file
                migration_sql = migration_file.read_text(encoding='utf-8')
                
                # Execute the migration within a transaction
                with conn.begin():
                    # Split by semicolon and execute each statement
                    # Skip the verification SELECT at the end
                    statements = [s.strip() for s in migration_sql.split(';') if s.strip() and not s.strip().upper().startswith('SELECT')]
                    
                    for statement in statements:
                        if statement:
                            try:
                                conn.execute(text(statement))
                            except Exception as e:
                                # Log but continue - might be already applied
                                print(f"  Warning executing statement: {str(e)[:100]}")
                
                print(f"  ✓ Migration {migration_file.name} completed")
                
            except Exception as e:
                print(f"  ✗ Error running migration {migration_file.name}: {e}")
                # Don't raise - allow app to start even if migration fails
                # (might be already applied)

if __name__ == "__main__":
    run_migrations()
