/*
 * -----------------------------------------------------------------------------
 * "THE BEER-WARE LICENSE" (Revision 42):
 * Lukas Niederbremer <webmaster@flippeh.de> and Clark Gaebel <cg.wowus.cg@gmail.com>
 * wrote this file. As long as you retain this notice you can do whatever you
 * want with this stuff. If we meet some day, and you think this stuff is worth
 * it, you can buy us a beer in return.
 *
 * "conversion" to D by Jakob Bornecrantz, no claim to copyright what so ever.
 * -----------------------------------------------------------------------------
 */

module lib.nbt.nbt;


extern (C):

enum nbt_status
{
    NBT_OK   =  0, /* No error. */
    NBT_ERR  = -1, /* Generic error, most likely of the parsing variety. */
    NBT_EMEM = -2, /* Out of memory. */
    NBT_EIO  = -3, /* IO error. */
    NBT_EZ   = -4  /* Zlib compression/decompression error. */
}

alias nbt_status.NBT_OK NBT_OK;
alias nbt_status.NBT_ERR NBT_ERR;
alias nbt_status.NBT_EMEM NBT_EMEM;
alias nbt_status.NBT_EIO NBT_EIO;
alias nbt_status.NBT_EZ NBT_EZ;

enum nbt_type
{
    TAG_INVALID    = 0, /* tag_end, but we don't use it in the in-memory representation. */
    TAG_BYTE       = 1, /* char, 8 bits, signed */
    TAG_SHORT      = 2, /* short, 16 bits, signed */
    TAG_INT        = 3, /* long, 32 bits, signed */
    TAG_LONG       = 4, /* long long, 64 bits, signed */
    TAG_FLOAT      = 5, /* float, 32 bits, signed */
    TAG_DOUBLE     = 6, /* double, 64 bits, signed */
    TAG_BYTE_ARRAY = 7, /* char *, 8 bits, unsigned, TAG_INT length */
    TAG_STRING     = 8, /* char *, 8 bits, signed, TAG_SHORT length */
    TAG_LIST       = 9, /* X *, X bits, TAG_INT length, no names inside */
    TAG_COMPOUND   = 10 /* nbt_tag * */
}

alias nbt_type.TAG_INVALID TAG_INVALID;
alias nbt_type.TAG_BYTE TAG_BYTE;
alias nbt_type.TAG_SHORT TAG_SHORT;
alias nbt_type.TAG_INT TAG_INT;
alias nbt_type.TAG_LONG TAG_LONG;
alias nbt_type.TAG_FLOAT TAG_FLOAT;
alias nbt_type.TAG_DOUBLE TAG_DOUBLE;
alias nbt_type.TAG_BYTE_ARRAY TAG_BYTE_ARRAY;
alias nbt_type.TAG_STRING TAG_STRING;
alias nbt_type.TAG_LIST TAG_LIST;
alias nbt_type.TAG_COMPOUND TAG_COMPOUND;

enum nbt_compression_strategy
{
    STRAT_GZIP,   /* Use a gzip header. Use this if you want your data to be
                     compressed like level.dat */

    STRAT_INFLATE /* Use a zlib header. Use this if you want your data to be
                     compressed like a chunk. */
}

/*
 * Represents a single node in the tree. You should switch on `type' and ONLY
 * access the union member it signifies. tag_compound and tag_list contain
 * recursive nbt_node entries, so those will have to be switched on too. I
 * recommended being VERY comfortable with recursion before traversing this
 * beast, or at least sticking to the library routines provided.
 */
struct nbt_node
{
    nbt_type type;
    char* name; /* This may be NULL. Check your damn pointers. */

    union { /* payload */

        /* tag_end has no payload */
        byte    tag_byte;
        short   tag_short;
        int     tag_int;
        long    tag_long;
        float   tag_float;
        double  tag_double;

        static struct nbt_byte_array_t {
            ubyte* data;
            int length;
        }
	nbt_byte_array_t tag_byte_array;

        char* tag_string; /* TODO: technically, this should be a UTF-8 string */

/+
        /*
         * Design addendum: we make tag_list a linked list instead of an array
         * so that nbt_node can be a true recursive data structure. If we used
         * an array, it would be incorrect to call free() on any element except
         * the first one. By using a linked list, the context of the node is
         * irrelevant. One tradeoff of this design is that we don't get tight
         * list packing when memory is a concern and huge lists are created.
         *
         * For more information on using the linked list, see `list.h'. The API
         * is well documented.
         */
        struct tag_list {
            struct nbt_node* data; /* A single node's data. */
            struct list_head entry;
        } *tag_list, /* The only difference between a list and a compound is its name */
          *tag_compound;
+/

    } /+payload+/;
}

               /***** High Level Loading/Saving Functions *****/

/*
 * Loads a NBT tree from a compressed file. The file must have been opened with
 * a mode of "rb". If an error occurs, NULL will be returned and errno will be
 * set to the appropriate nbt_status. Check your danm pointers.
 */
/+
nbt_node* nbt_parse_file(FILE* fp);
+/

/*
 * The same as nbt_parse_file, but opens and closes the file for you.
 */
nbt_node* nbt_parse_path(const(char)* filename);

/*
 * Loads a NBT tree from a compressed block of memory (such as a chunk or a
 * pre-loaded level.dat). If an error occurs, NULL will be returned and errno
 * will be set to the appropriate nbt_status. Check your damn pointers.
 *
 * PROTIP: Memory map each individual region file, then call
 *         nbt_parse_compressed for chunks as needed.
 */
nbt_node* nbt_parse_compressed(const(void)* chunk_start, size_t length);

/*
 * Dumps a tree into a file. Check your damn error codes. This function should
 * return NBT_OK.
 *
 * @see nbt_compression_strategy
 */
/+
nbt_status nbt_dump_file(/+const+/ nbt_node* tree,
                         FILE* fp, nbt_compression_strategy);
+/

/*
 * Dumps a tree into a block of memory. If an error occurs, a buffer with a NULL
 * `data' pointer will be returned, and errno will be set.
 *
 * 1) Check your damn pointers.
 * 2) Don't forget to free buf->data. Memory leaks are bad, mkay?
 *
 * @see nbt_compression_strategy
 */
/+
struct buffer nbt_dump_compressed(/+const+/ nbt_node* tree,
                                  nbt_compression_strategy);
+/

                /***** Low Level Loading/Saving Functions *****/

/*
 * Loads a NBT tree from memory. The tree MUST NOT be compressed. If an error
 * occurs, NULL will be returned, and errno will be set to the appropriate
 * nbt_status. Please check your damn pointers.
 */
nbt_node* nbt_parse(const(void)* memory, size_t length);

/*
 * Returns a NULL-terminated string as the ascii representation of the tree. If
 * an error occurs, NULL will be returned and errno will be set.
 *
 * 1) Check your damn pointers.
 * 2) Don't forget to free the returned pointer. Memory leaks are bad, mkay?
 */
char* nbt_dump_ascii(const(nbt_node)* tree);

/*
 * Returns a buffer representing the uncompressed tree in Notch's official
 * binary format. Trees dumped with this function can be regenerated with
 * nbt_parse. If an error occurs, a buffer with a NULL `data' pointer will be
 * returned, and errno will be set.
 *
 * 1) Check your damn pointers.
 * 2) Don't forget to free buf->data. Memory leaks are bad, mkay?
 */
/+
struct buffer nbt_dump_binary(/+const+/ nbt_node* tree);
+/

                   /***** Tree Manipulation Functions *****/

/*
 * Clones an existing tree. Returns NULL on memory errors.
 */
nbt_node* nbt_clone(nbt_node*);

/*
 * Recursively deallocates a node and all its children. If this is used on a an
 * entire tree, no memory will be leaked.
 */
void nbt_free(nbt_node*);

/*
 * Recursively frees all the elements of a list, and then frees the list itself.
 */
/+
void nbt_free_list(struct tag_list*);
+/

/*
 * A visitor function to traverse the tree. Return true to keep going, false to
 * stop. `aux' is an optional parameter which will be passed to your visitor
 * from the parent function.
 */
alias bool function(nbt_node* node, void* aux) nbt_visitor_t;

/*
 * A function which directs the overall algorithm with its return type.
 * `aux' is an optional parameter which will be passed to your predicate from
 * the parent function.
 */
alias bool function(const(nbt_node)* node, void* aux) nbt_predicate_t;

/*
 * Traverses the tree until a visitor says stop or all elements are exhausted.
 * Returns false if it was terminated by a visitor, true otherwise. In most
 * cases this can be ignored.
 *
 * TODO: Is there a way to do this without expensive function pointers? Maybe
 * something like list_for_each?
 */
bool nbt_map(nbt_node* tree, nbt_visitor_t, void* aux);

/*
 * Returns a new tree, consisting of a copy of all the nodes the predicate
 * returned `true' for. If the new tree is empty, this function will return
 * NULL. If an out of memory error occured, errno will be set to NBT_EMEM.
 *
 * TODO: What if I want to keep a tree and all of its children? Do I need to
 * augment nbt_node with parent pointers?
 */
nbt_node* nbt_filter(const(nbt_node)* tree, nbt_predicate_t, void* aux);

/*
 * The exact same as nbt_filter, except instead of returning a new tree, the
 * existing tree is modified in place, and then returned for convenience.
 */
nbt_node* nbt_filter_inplace(nbt_node* tree, nbt_predicate_t, void* aux);

/*
 * Returns the first node which causes the predicate to return true. If all
 * nodes are rejected, NULL is returned. If you want to find every instance of
 * something, consider using nbt_map with a visitor that keeps track.
 *
 * Since const-ing `tree' would require me const-ing the return value, you'll
 * just have to take my word for it that nbt_find DOES NOT modify the tree.
 * Feel free to cast as necessary.
 */
nbt_node* nbt_find(nbt_node* tree, nbt_predicate_t, void* aux);

/*
 * Returns the first node with the name `name'. If no node with that name is in
 * the tree, returns NULL.
 *
 * If `name' is NULL, this function will find the first unnamed node.
 *
 * Since const-ing `tree' would require me const-ing the return value, you'll
 * just have to take my word for it that nbt_find DOES NOT modify the tree.
 * Feel free to cast as necessary.
 */
nbt_node* nbt_find_by_name(nbt_node* tree, const(char)* name);

/*
 * Returns the first node with the "path" in the tree of `path'. If no such node
 * exists, returns NULL. If an element has no name, something like:
 *
 * root.subelement..data == "root" -> "subelement" -> "" -> "data"
 *
 * Remember, if multiple elements exist in a sublist which share the same name
 * (including ""), the first one will be chosen.
 */
nbt_node* nbt_find_by_path(nbt_node* tree, const(char)* path);

/* Returns the number of nodes in the tree. */
size_t nbt_size(const(nbt_node)* tree);

/* TODO: More utilities as requests are made and patches contributed. */

                      /***** Utility Functions *****/

/* Returns true if the trees are identical. */
bool nbt_eq(const(nbt_node)* /+restrict+/ a, const(nbt_node)* /+restrict+/ b);

/*
 * Converts a type to a print-friendly string. The string is statically
 * allocated, and therefore does not have to be freed by the user.
*/
const(char)* nbt_type_to_string(nbt_type);

/*
 * Converts an error code into a print-friendly string. The string is statically
 * allocated, and therefore does not have to be freed by the user.
 */
const(char)* nbt_error_to_string(nbt_status);


extern (D):

string licenseText = `
"THE BEER-WARE LICENSE" (Revision 42):
Lukas Niederbremer <webmaster@flippeh.de> and Clark Gaebel <cg.wowus.cg@gmail.com>
wrote this file. As long as you retain this notice you can do whatever you
want with this stuff. If we meet some day, and you think this stuff is worth
it, you can buy us a beer in return.
`;

import license;

static this() {
   licenseArray ~= licenseText;
}
