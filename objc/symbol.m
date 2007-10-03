// symbol.m
//  A class for Nu symbols and symbol tables.
//
//  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

#import "symbol.h"
#import "st.h"
#import "class.h"
#import "object.h"

static NuSymbolTable *sharedSymbolTable = 0;

@implementation NuSymbolTable

+ (NuSymbolTable *) sharedSymbolTable
{
    if (!sharedSymbolTable) {
        sharedSymbolTable = [[self alloc] init];
    }
    return sharedSymbolTable;
}

- (void) dealloc
{
    NSLog(@"WARNING: deleting a symbol table. Leaking stored symbols.");
    [super dealloc];
}

// Designated initializer
- (id) symbolWithCString:(const char *)string
{
    if (!symbol_table) symbol_table = st_init_strtable();

    // If the symbol is already in the table, return it.
    NuSymbol *symbol;
    if (st_lookup(symbol_table, (st_data_t)string, (st_data_t *)&symbol))
        return symbol;

    // If not, create it. Don't autorelease it; it is owned by the table.
    symbol = [[NuSymbol alloc] init];             // keep construction private
    symbol->string = strdup(string);
    int len = strlen(string);
    symbol->isLabel = (string[len - 1] == ':');
    symbol->isGensym = (len > 2) && (string[0] == '_') && (string[1] == '_');

    // Put the new symbol in the symbol table and return it.
    st_add_direct(symbol_table, (st_data_t)(symbol->string), (long) symbol);
    return symbol;
}

- (id) symbolWithString:(NSString *)string
{
    return [self symbolWithCString:[string cStringUsingEncoding:NSUTF8StringEncoding]];
}

- (id) symbolWithBytes:(const void *)bytes length:(unsigned)length
{
    char buffer[1024];                            // overrun risk!!
    strncpy(buffer, bytes, length);
    buffer[length] = 0;
    return [self symbolWithCString:buffer];
}

- (id) lookup:(const char *) string
{
    NuSymbol *symbol;
    return st_lookup(symbol_table, (st_data_t)string, (st_data_t *)&symbol) ? symbol : nil;
}

// helper function for "all" method
static int add_to_array(st_data_t k, st_data_t v, st_data_t d)
{
    NuSymbol *symbol = (NuSymbol *) v;
    NSMutableArray *array = (NSMutableArray *) d;
    [array addObject:symbol];
    return ST_CONTINUE;
}

- (NSArray *) all
{
    NSMutableArray *array = [[[NSMutableArray alloc] init] autorelease];
    st_foreach(symbol_table, add_to_array, (long) array);
    return array;
}

@end

@implementation NuSymbol

- (void) dealloc
{
    free(string);
    [super dealloc];
}

- (id) value
{
    return value;
}

- (void) setValue:(id)v
{
    [v retain];
    [value release];
    value = v;
}

- (NSString *) description
{
    return [NSString stringWithCString:string encoding:NSUTF8StringEncoding];
}

- (NSString *) stringValue
{
    return [NSString stringWithCString:string encoding:NSUTF8StringEncoding];
}

- (int) intValue
{
    return (value == [NSNull null]) ? 0 : 1;
}

- (const char *) string
{
    return string;
}

- (bool) isGensym
{
    return isGensym;
}

- (bool) isLabel
{
    return isLabel;
}

- (NSString *) labelName
{
    if (isLabel)
        return [[self stringValue] substringToIndex:[[self stringValue] length] - 1];
    else
        return [self stringValue];
}

- (id) evalWithContext:(NSMutableDictionary *)context
{

    char c = (char) [[self stringValue] characterAtIndex:0];
    // If the symbol is a class instance variable, find "self" and ask it for the ivar value.
    if (c == '@') {
        NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
        id object = [context objectForKey:[symbolTable symbolWithCString:"self"]];
        if (!object) return [NSNull null];
        id ivarName = [[self stringValue] substringFromIndex:1];
        id result = [object valueForIvar:ivarName];
        return result ? result : [NSNull null];
    }

    // Next, try to find the symbol in the local evaluation context.
    id valueInContext = [context objectForKey:self];
    if (valueInContext)
        return valueInContext;

    // if it's not there, try the next context up
    id parentContext = [context objectForKey:@"context"];
    if (parentContext) {
        valueInContext = [parentContext objectForKey:self];
        if (valueInContext)
            return valueInContext;
    }

    // Next, return the global value assigned to the value.
    if (value)
        return value;

    // If the symbol is a label (ends in ':'), then it will evaluate to itself.
    if (isLabel)
        return self;

    // If the symbol is still unknown, try to find a class with this name.
    id className = [self stringValue];
    value = [NuClass classWithName:className];
    if (value)
        return value;

    // Undefined globals evaluate to null.
    if (c == '$')
        return [NSNull null];

    // Still-undefined symbols evaluate to null... maybe this should throw an exception.
    [NSException raise:@"NuUndefinedSymbol" format:@"undefined symbol: %@", [self stringValue]];
    NSLog(@"undefined symbol: %@", self);
    return [NSNull null];
}

- (NSComparisonResult) compare:(NuSymbol *) anotherSymbol
{
	return strcmp(string, anotherSymbol->string);
}

- (id) copyWithZone:(NSZone *) zone
{
    // Symbols are unique, so we don't copy them, but we retain them again since copies are automatically retained.
    return [self retain];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:[self stringValue]];
}

- (id) initWithCoder:(NSCoder *)coder
{
    [super init];
    [self autorelease];
    return [[NuSymbolTable sharedSymbolTable] symbolWithString:[coder decodeObject]];
}

@end