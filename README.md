# Far Cry 2 Stealing Boots Jackal Tapes Patcher
## Insanity
Did I ever tell you what the definition of insanity is? Insanity is doing the exact… same f___ing thing… over and over again, expecting… s__t to change. Insanity is when you pick up another Jackal Tape expecting of hearing something further than “Stealing Boots”. No, no, no, no, no, please! This time it’s gonna be different record!

Insanity is when a bug is not fixed for 10 years.
## Signs and symptoms
With v1.03 update, a bug was introduced that does not allow to listen and does not mark as taken the tapes from the second southern map (Bowa-Seko) further than #09 “Stealing Boots”. The first picked up tape on this map is written as #09 “Stealing Boots”, and all subsequent tapes on the same map will simply repeat it, forcing to listen again and again as Jackal tells a sad story about a kid stealing boots from a dead soldier.
## Causes
During the game, a list of 17 tapes is kept in memory, in which, among other things, the following information is noted:
 
![Screenshot](Screenshots/TapesTable.png?raw=true)
>Figure 1. Illustration of a list of tapes in memory. The IsTaken field is filled in for example. The FromMap1 field is always filled like this.

The picture above shows 17 tapes. Number 00 is a tape given by Reuben Oluwagembi at the beginning of the game, the rest are scattered around the world. The field IsTaken will be set with “1”, marking tape as picked up. The field FromMap1 is pre-populated when the game (or save) is loaded, marking with the “1” all tapes from the first north map (Leboa-Sako).

When the next voice recorder is picked up, the NewJackalTapeFound subroutine is triggered in the game engine. Tapes from the list are checked one by one for: whether it is marked as taken, and to which map it belongs. Finally, depending on which map you are standing on now, the decision is made: to play the tape and mark it as picked up or look further down the list.

It's simple. Look at this correctly working scheme from the versions of the game from 1.00 to 1.02: 
![Screenshot](Screenshots/Logic100.png?raw=true)
>Figure 2. The correct logic of the NewJackalTapeFound subroutine. Green - YES. Red - NO.

Note that if the “Tape Taken” check shows that this tape is marked in the list as picked up, it immediately goes along the green arrow to the next one in the list (Next). According to this logic, tapes from 00 to 08 will be played (and marked) only if you picked up a voice recorder on the first map, and tapes from 09 to 16 - only if on the second.

After update 1.03, the subroutine logic has changed a bit:
![Screenshot](Screenshots/Logic103.png?raw=true)
>Figure 3. Incorrect logic of the NewJackalTapeFound subroutine after update 1.03

Notice where the green arrow goes from “Tape Taken” check. Suppose that we passed into the second act, we are standing on the second map and the situation with the films we have as in the table above: three were found on the first map (two plus one from Reuben), and one was found on the second map. Next time, when on the second map we pick up the voice recorder, the first three tapes (00-02) will follow the path:

    Tape Taken --> YES --> 1st  Map --> NO --> Tape from 2nd Map --> NO --> Next
Tapes 03-08 will follow the path:

    Tape Taken --> NO --> 1st  Map --> NO --> Tape from 2nd Map --> NO --> Next
But film 09, despite the fact that it has already been marked as taken, will follow the path:

    Tape Taken --> YES --> 1st  Map --> NO --> Tape from 2nd Map --> YES --> PLAY

Here is the glitch!

All other changes in the scheme miraculously did not affect the logic. Even if you simply return the green arrow from “Tape Taken” back to “Next”, everything will work as it should.

This error is another confirmation of the statement “If it ain't broken, why fix it”. Perhaps, during some refactoring of the NewJackalTapeFound method, some brackets ware put in wrong place of the source code, and the logic changed.
## Treatment
To eliminate the error, it is actually enough to change just one byte in the Dunia.DLL file to turn the logic of the subroutine in the right direction.
### Self-medication
If you are confident in what you are doing and are familiar with hex editors, then this is what you need to do.
1	Find where the game is installed - the desired file is located in the BIN subfolder.
2	Of course, make a backup copy of the Dunia.DLL file, just in case.
3	Then open the file and find the following sequence of bytes:
**0A** 3B CA 75 0A
4	If found, then, to be completely sure, check that the file size is equal to 20183176 bytes, and the desired sequence was found at offset 0x0074D865.
5	Change the first byte of the sequence from 0x0A to 0x14. Now it should look like this:
**14** 3B CA 75 0A
### Visit doctor
Those who do not want to bother with manually editing the file can try an easy-to-use patcher:

https://github.com/FoxAhead/Far-Cry-2-Stealing-Boots-Jackal-Tapes-Patcher/releases/latest

Download and run the file FarCry2StealingBootsJackalTapesPatcher.exe. Use the Browse button to select the Dunia.DLL file. Click Patch!
On the start, the program will try to automatically determine the installation path of the game, so the Browse button should immediately take you to the desired folder, and all that remains is to select the Duina.DLL file. Before applying the patch, the program checks the file, and if everything is in OK, then the Patch button! below will be enabled to click. The backup will be created automatically as soon as you confirm patching. If at any of the stages something goes wrong, the program will report that.
The patcher searches for a suitable pattern of bytes using mask, so theoretically it is able to correct the subroutine even in some exotic Dunia.DLL file (other size, other addresses), provided that there really is an erroneous subroutine.
## Prognosis
The final recovery can be considered only if, before applying the patch, you picked up no more than one tape on the second map. Otherwise, all subsequent picked up tapes simply disappeared irretrievably, without appearing in the list. In this case, look for an earlier save. Or ... why not replay the game?

![Screenshot](Screenshots/InGameGlutenFreeTape.jpg?raw=true)

## P.S.
Did I ever tell you 
what the definition
 of insanity is?
