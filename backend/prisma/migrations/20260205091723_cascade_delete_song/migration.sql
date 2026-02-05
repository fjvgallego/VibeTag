-- DropForeignKey
ALTER TABLE "SongTag" DROP CONSTRAINT "SongTag_songId_fkey";

-- AddForeignKey
ALTER TABLE "SongTag" ADD CONSTRAINT "SongTag_songId_fkey" FOREIGN KEY ("songId") REFERENCES "Song"("id") ON DELETE CASCADE ON UPDATE CASCADE;
