#import <Foundation/Foundation.h>

@protocol ChessboardDelegate<NSObject>
- (void)initBoardWithFEN:(NSString *)fen 
                     SAN:(NSString *)san 
             pgnMoveText:(NSString *)pgnMoveText;
- (void)executeJS:(NSString *)jsFunctionCall;

-(void) showCoords;

@end