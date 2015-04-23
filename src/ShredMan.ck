public class ShredMan {
    int shred[0];
    
    fun void add_shred( int i ) {
        shred << i;
    }

    fun void kill_shred( int i ) {
        if( shred.size() > 0 ) {
            Shred.fromId( shred[i] ).exit();
            if( shred.size() > 1 ) {
                for( i => int j; j < shred.size()-1; j++ ) {
                    shred[j] @=> shred[j+1];
                }
            }
            shred.size( shred.size() - 1 );
        }
    }

    fun void print_shreds() {
        for( int i; i < shred.size(); i++ ) {
            chout <= shred[i]+", ";
        }
        chout <= "\n";
        chout.flush();
    }
}
