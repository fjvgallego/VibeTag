-- DropForeignKey
ALTER TABLE "SongTag" DROP CONSTRAINT "SongTag_tagId_fkey";

-- AddForeignKey
ALTER TABLE "SongTag" ADD CONSTRAINT "SongTag_tagId_fkey" FOREIGN KEY ("tagId") REFERENCES "Tag"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
