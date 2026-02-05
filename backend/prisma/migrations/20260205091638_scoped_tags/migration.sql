/*
  Warnings:

  - A unique constraint covering the columns `[name,ownerId]` on the table `Tag` will be added. If there are existing duplicate values, this will fail.

*/
-- CreateIndex
CREATE UNIQUE INDEX "Tag_name_ownerId_key" ON "Tag"("name", "ownerId");

-- DropIndex
DROP INDEX "Tag_name_key";

-- AlterTable
ALTER TABLE "Song" ADD COLUMN     "album" TEXT,
ADD COLUMN     "genre" TEXT;
