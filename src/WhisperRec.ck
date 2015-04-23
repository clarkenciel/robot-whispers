public class WhisperRec extends Chubgraph {
    adc => LiSa l => FFT fft => blackhole;
    IFFT ifft => BPF b =>  dac;
    TriOsc t => blackhole;
    TriOsc t2 => blackhole;
    
    t.freq( 0.1 );
    t.gain( 10 );
    t2.freq( 0.1 );
    t2.gain( 250 );
    t2.phase( 0.5 * pi );
    500 => float bFreq => b.freq;

    4 => fft.size => int FFT_SIZE => int HOP_SIZE;
    while( HOP_SIZE <= 2 ) 4 *=> HOP_SIZE;
    
    Windowing.hann(FFT_SIZE/2) => fft.window;

    UAnaBlob blob;
    complex Z[FFT_SIZE/2];
    
    dur chunks[0][0]; // store chunks of recordings
    dur start, stop;
    int start_idx;
    
    l.duration( minute );
    
    // FUNCS
    fun void init( dur duration ) {
        l.duration( duration );
    }
    fun void chunk_in_order( int chunk_id, ShredMan sm ) {
        //<<< "chunk in order!","">>>;
        sm.add_shred( me.id() );

        chunks[chunk_id] @=> dur chunk[];
        l.rate(1);

        while( true ) {
            for( int i; i < chunk.size()-1; i++ ){
                play( chunk[i], chunk[i+1] );
            }
        }
    }
    
    // play a random part of a chunk
    fun void sub_chunk( int chunk_id, ShredMan sm ) {
        //<<< "sub chunk!","" >>>;
        sm.add_shred( me.id() );

        int chunk_idx, start_idx, end_idx, num_chunks;
        dur chunk[];
        chunks[chunk_id] @=> chunk;
        chunk.size() => num_chunks;

        while( true ) { 
            for( int i; i < num_chunks; i++ ) {
                while( start_idx == end_idx ) {
                    Math.random2(0, num_chunks-1) => start_idx;
                    Math.random2(0, num_chunks-1) => end_idx;
                }
    
                if( end_idx > start_idx ) {
                    l.rate(1);
                    play( chunk[start_idx], chunk[end_idx] );
                } else {
                    l.rate(-1);
                    play( chunk[end_idx], chunk[start_idx] );
                }
            }
        }
    }
    
    fun void record_chunk( dur tot_len, int num_chunks ) {
        (tot_len/samp) / (num_chunks $ float) => float chunk_len;
        dur chunk[0];
        for( int i; i < num_chunks; i ++ )
            record( chunk, chunk_len::samp );
        
        chunk << l.recPos();
        chunks.size(chunks.size()+1);
        new dur[num_chunks] @=> chunks[chunks.size()-1];
        chunk @=> chunks[chunks.size()-1];
    }
    
    fun void record( dur chunk_arr[], dur d ) {
        chunk_arr << l.recPos();
        l.record(1);
        d => now;
        l.record(0);
    }
    
    fun void play( dur start, dur stop ) {
        //<<< "playing:",start/second,"to",stop/second,"">>>;
        l.playPos( start );
        l.play(1);
        (stop - start) + now => time later;
        while( now < later ) {
            fft.upchuck() @=> blob;
            blob.cvals() @=> Z;
            ifft.transform(Z);

            Math.fabs(t.last()) + 1 => b.Q;
            Math.fabs(t2.last()) + bFreq => b.freq;
            HOP_SIZE::samp => now;
        }
        l.play(0);
    }
}
