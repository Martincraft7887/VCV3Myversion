function onNoteHit(e)
{
    var ntString = [];
    if (e.noteType != null)
        ntString = e.noteType.split(); // array of every character in the string
    if (!ntString.contains("-"))
        return;

    var array = [];

    for (i in 0...ntString.length)
    {
        if (i % 4 == 0)
        {
            // "1-1," pushes strumLines.members[1].characters[1]
            array.push(strumLines.members[ntString[i]].characters[ntString[i + 2]]);
        }
    }

    if (array != [])
        e.characters = array;
}