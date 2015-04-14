// score.ck 
// WORD SCRAMBLE 
// generative score for robot_whispers.ck

/*
["the", "quick", "brown", "fox", "jumps", "over", "the", "lazy", "dog",
"the", "quick", "brown", "fox", "jumps", "over", "the", "lazy", "dog",
 "the", "quick", "brown", "fox", "jumps", "over", "the", "lazy", "dog",
  "the", "quick", "brown", "fox", "jumps", "over", "the", "lazy", "dog" ]@=> string words[];
  */
["so","much","depends","upon","a","red","wheel","barrow","glazed","with","rain",
    "water","beside","the","white","chickens","ghost","ghost","ghost","ghost",
    "ghost","ghost","ghost","ghost","ghost","ghost","ghost","ghost","ghost",
    "ghost","ghost","ghost","ghost","toast","toast","toast","toast","toast",
    "toast"] @=> string words[];

adc => FFT fft => blackhole;
UAnaBlob blob;

second / samp => float srate;

float res[0];
float sums[0];
float sum, maxVal, div;
time later, runStart, runEnd;
int c, idx, maxIdx, wIdx, N, win, frames, pCount;
dur runTime;
string word;

//--------------INTRO---------------------
"\n\tWELCOME TO WORD SCRAMBLE! PREPARE TO SAY FUNNY THINGS!\n\t" => word;
"------------------------------------------------------" +=> word;
<<< word,"">>>;
for( 3 => int i; i > 0; i-- ) {
    <<< "\t"+i+"...","">>>;
    second => now;
}
now => runStart;
//----------------PIECE--------------------
while( words.size() > 0  ) {
    words[wIdx] => word;
    sums.size( word.length() );
    word.length() * 0.25 => div;
    <<< "\n\tSay:\""+word+"\"\n\t...","">>>;

    (div)::second => now; // wait to catch our breath

    now + div::second => later;
    ((div::second)/samp) $ int => frames;
    frames/word.length() => N => win => fft.size;
    Windowing.hamming(N) => fft.window;

    0 => idx;
    0 => c;

    <<< "\n\t\t\t...NOW! ("+Std.ftoa(div,2)+" seconds)","" >>>;
    while( now < later ) {
        win::samp => now;

        fft.upchuck() @=> blob;
        blob.fvals() @=> res;

        for( int i; i < res.size();i ++ )
            res[i] +=> sum;

        res.size() /=> sum;

        if( idx < word.length() )
            sum @=> sums[idx];
        
        idx++;
    }

    // show letter heat and find max
    0 => maxIdx;
    sums[0] => maxVal;
    for( int i; i < word.length(); i++ ) {
        if( sums[i] >= maxVal ) {
            sums[i] => maxVal;
            i => maxIdx;
        }
    }

    // grow max val letter 
    maxIdx + 1 => idx;
    while( idx <= word.length() + 1 
            && word.substring(maxIdx,1) == word.substring(idx%word.length(),1) )
        idx++;

    if( idx > word.length() + 1 && words.size() > 1 ) {
        for( wIdx+1 => int i; i < words.size(); i++ ) 
            words[i % words.cap()] @=> words[i-1]; 
        words.size( words.size() - 1 );
        (wIdx+1)%words.size() => wIdx;
    } else if( idx > word.length() + 1 && words.size() == 1 ) {
        words.size( words.size() - 1 );
    } else {
        word.replace( idx % word.length(), 1, word.substring(maxIdx,1) );
        word @=> words[ wIdx ];
        if( pCount < 9 )
            (wIdx+1)%words.size() => wIdx;
        else
            Math.random2(0, words.size()-1) => wIdx;
    }

/*
    chout <= "\n\tPHRASE:\n\t";
    for( int i; i < words.size(); i ++ ) {
        chout <= words[i] + ", ";
    }
    */
    chout <= "\n\t---------------------------\n";chout.flush();
    pCount++;
}
now => runEnd;
runEnd - runStart => runTime;
<<< "\n\tTOTAL RUNTIME:", runTime/second,"seconds", "" >>>;
