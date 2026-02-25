-- ============================================
-- Migration 007: Add updated_at column to attendance table
-- Date: 2026-02-22
-- Purpose: attendance tablosuna updated_at kolonu ekle
-- ============================================

-- updated_at kolonunu ekle
ALTER TABLE attendance 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP;

-- Mevcut kayıtlar için updated_at'i created_at ile aynı yap
UPDATE attendance 
SET updated_at = created_at 
WHERE updated_at IS NULL;

-- updated_at'i NOT NULL yap
ALTER TABLE attendance 
ALTER COLUMN updated_at SET NOT NULL;

-- updated_at otomatik güncellensin
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger oluştur
DROP TRIGGER IF EXISTS update_attendance_updated_at ON attendance;

CREATE TRIGGER update_attendance_updated_at
    BEFORE UPDATE ON attendance
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
