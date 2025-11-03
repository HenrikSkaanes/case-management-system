-- Migration: Add AI Agent fields to tickets table
-- Date: 2025-11-03
-- Description: Adds fields to support AI-generated ticket drafts and stage tracking

-- Add AI agent-related columns
ALTER TABLE tickets 
ADD COLUMN IF NOT EXISTS ai_generated BOOLEAN DEFAULT FALSE NOT NULL;

ALTER TABLE tickets 
ADD COLUMN IF NOT EXISTS ai_draft_content TEXT;

ALTER TABLE tickets 
ADD COLUMN IF NOT EXISTS ai_sources JSON;

ALTER TABLE tickets 
ADD COLUMN IF NOT EXISTS ai_confidence_score REAL;  -- Float type in PostgreSQL

ALTER TABLE tickets 
ADD COLUMN IF NOT EXISTS ai_model_version VARCHAR(100);

ALTER TABLE tickets 
ADD COLUMN IF NOT EXISTS ai_generated_at TIMESTAMP WITH TIME ZONE;

-- Create index on ai_generated for filtering AI tickets
CREATE INDEX IF NOT EXISTS idx_tickets_ai_generated ON tickets(ai_generated);

-- Update status enum to include new AI stages
-- Note: PostgreSQL doesn't support ALTER TYPE directly for enums
-- Need to add new values one by one
DO $$ 
BEGIN
    -- Check if value exists before adding
    IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'ai_draft' AND enumtypid = 'ticketstatus'::regtype) THEN
        ALTER TYPE ticketstatus ADD VALUE 'ai_draft';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'in_review' AND enumtypid = 'ticketstatus'::regtype) THEN
        ALTER TYPE ticketstatus ADD VALUE 'in_review';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'awaiting_customer' AND enumtypid = 'ticketstatus'::regtype) THEN
        ALTER TYPE ticketstatus ADD VALUE 'awaiting_customer';
    END IF;
END $$;

-- Add comment to document the AI fields
COMMENT ON COLUMN tickets.ai_generated IS 'Flag indicating if this ticket was initially drafted by AI agent';
COMMENT ON COLUMN tickets.ai_draft_content IS 'Original AI-generated response draft before any edits';
COMMENT ON COLUMN tickets.ai_sources IS 'JSON array of knowledge base sources used by AI (citations)';
COMMENT ON COLUMN tickets.ai_confidence_score IS 'AI agent confidence score between 0.0 and 1.0';
COMMENT ON COLUMN tickets.ai_model_version IS 'Version/name of AI model that generated the draft (e.g., gpt-4o-2024-05-13)';
COMMENT ON COLUMN tickets.ai_generated_at IS 'Timestamp when AI draft was generated';

-- Verify migration
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'tickets' 
    AND column_name LIKE 'ai_%'
ORDER BY ordinal_position;
