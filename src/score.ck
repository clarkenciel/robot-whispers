// score.ck 
// WORD SCRAMBLE 
// generative score for robot_whispers.ck
["Although","the","content","represents","your","concepts","theres","a","structural",
"relationship","between","that","content",
"entities","that","should","represent",
"the","relationship","between","the","concepts",
"of","human","thought"] @=> string words[];

words.size() => int start_size;
int chunk_idx[start_size][0]; // indexes words to chunks
3::minute => dur whisper_dur;
dur t_count;

if( me.args() )
    Std.atof(me.arg(0))::minute => whisper_dur;
else
    <<< "FYI: You may set your whisper duration with an argument. DEFAULT IS 5 MIN","">>>;

WhisperRec wr;
WhisperEvent we;
ShredMan sm;

wr.init(whisper_dur);
adc => FFT fft => blackhole;
UAnaBlob blob;

second / samp => float srate;

float res[0];
float sums[0];
float sum, maxVal, div;
time later, runStart, runEnd;
int c, idx, maxIdx, wIdx, N, win, frames, pCount, chunk_choice;
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
spork ~ record_listen( we );

while( words.size() > 0  ) {
    sm.print_shreds();
    words[wIdx] => word;
    sums.size( word.length() );
    word.length() * 0.25 => div;
    <<< "\n\tSay:\""+word+"\"\n\t...","">>>;

    div::second => now; // wait to catch our breath

    (div::second/samp) $ int => frames;
    frames/word.length() => N => win => fft.size;
    Windowing.hamming(N) => fft.window;

    0 => idx;
    0 => c;

    for( 3 => int i; i > 0; i-- ) {
        <<< "\t\t"+i,". . .", "" >>>;
        div::second => now;
    }
    <<< "\n\t\t...NOW! ("+Std.ftoa(div,2)+" seconds)","" >>>;
    // set up chunk recorder
    div::second => we.record_length;
    word.length() => we.record_size;
    wIdx => we.chunk_id; 
    we.broadcast();

    // choose chunk to play 
    if( wr.chunks.size() > 1 && chunk_idx[wIdx].size()-1 >= 0 ) {
        Math.random2(0, chunk_idx[wIdx].size()-1) => chunk_choice;        
        spork ~ play_whisper( chunk_idx[wIdx][chunk_choice], sm );
        sm.kill_shred(0);
    }

    now + div::second => later;
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
    while( idx <= word.length() + 1 && word.substring(maxIdx,1) == word.substring(idx%word.length(),1) )
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
        if( pCount < words.size() )
            (wIdx+1)%words.size() => wIdx;
        else
            Math.random2(0, words.size()-1) => wIdx;
    }

    chout <= "\n\tPHRASE:\n\t";
    for( int i; i < words.size(); i ++ ) {
        chout <= words[i] + ", ";
    }
    chout <= "\n\t---------------------------\n";chout.flush();
   
    pCount++;
    div::second +=> t_count;
}

now => runEnd;
runEnd - runStart => runTime;
<<< "\n\tTOTAL RUNTIME:", runTime/second,"seconds", "" >>>;

// FUNCS
fun void record_listen( WhisperEvent e ) {
    while( true ) {
        e => now;
        wr.record_chunk(e.record_length, e.record_size);
        //<<< e.chunk_id, chunk_idx.size(), "" >>>;
        chunk_idx[e.chunk_id] << wr.chunks.size()-1;
    }
}

fun void play_whisper( int chunk_id, ShredMan se ) {
    Math.random2(0,1) => int choice;
    if( choice )
        wr.sub_chunk( chunk_id, se );
    else
        wr.chunk_in_order( chunk_id, se );
}
