public class WhisperRec extends Chubgraph {
    adc => LiSa l => dac;
    dur chunks[0][0]; // store chunks of recordings
    dur start, stop;
    int start_idx;
    
    l.duration( minute );
    
    // FUNCS
    fun void init( dur duration ) {
        l.duration( duration );
    }
    fun void chunk_in_order( dur chunk[] ) {
        <<< "chunk in order!","">>>;
        for( int i; i < chunk.size()-1; i++ )
            play( chunk[i], chunk[i+1] );
    }
    
    // play a random part of a chunk
    fun void sub_chunk( int num_chunks ) {
        <<< "sub chunk!","" >>>;
        int chunk_idx, start_idx, end_idx;
        dur chunk[];
        Math.random2(0, chunks.size()-1) => chunk_idx;
        chunks[chunk_idx] @=> chunk;
        
        for( int i; i < num_chunks; i++ ) {
            Math.random2(0, chunk.size()-2) => start_idx;
            Math.random2(start_idx+1, chunk.size()-1) => end_idx;
            
            play( chunk[start_idx], chunk[end_idx] );
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
        <<< "playing:",start/second,"to",stop/second,"">>>;
        l.playPos( start );
        l.play(1);
        (stop-start) => now;
        l.play(0);
    }
}