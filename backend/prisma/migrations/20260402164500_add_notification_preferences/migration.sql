-- AlterTable
ALTER TABLE "users"
ADD COLUMN "notif_push_enabled" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN "notif_new_messages" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN "notif_listing_updates" BOOLEAN NOT NULL DEFAULT true;
