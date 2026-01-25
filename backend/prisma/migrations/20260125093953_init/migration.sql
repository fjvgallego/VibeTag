-- CreateEnum
CREATE TYPE "TagType" AS ENUM ('SYSTEM', 'USER');

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "appleUserIdentifier" TEXT NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Song" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "artist" TEXT NOT NULL,
    "artworkUrl" TEXT,

    CONSTRAINT "Song_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Tag" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "color" TEXT NOT NULL,
    "type" "TagType" NOT NULL,
    "ownerId" TEXT,

    CONSTRAINT "Tag_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SongTag" (
    "id" TEXT NOT NULL,
    "songId" TEXT NOT NULL,
    "tagId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,

    CONSTRAINT "SongTag_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_appleUserIdentifier_key" ON "User"("appleUserIdentifier");

-- CreateIndex
CREATE UNIQUE INDEX "SongTag_songId_tagId_userId_key" ON "SongTag"("songId", "tagId", "userId");

-- AddForeignKey
ALTER TABLE "Tag" ADD CONSTRAINT "Tag_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SongTag" ADD CONSTRAINT "SongTag_songId_fkey" FOREIGN KEY ("songId") REFERENCES "Song"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SongTag" ADD CONSTRAINT "SongTag_tagId_fkey" FOREIGN KEY ("tagId") REFERENCES "Tag"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SongTag" ADD CONSTRAINT "SongTag_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
