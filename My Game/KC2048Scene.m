//
//  KC2048Scene.m
//  My Game
//
//  Created by Keith Carscadden on 2014-03-28.
//  Copyright (c) 2014 Keith Carscadden. All rights reserved.
//

#import "KC2048Scene.h"

@interface KC2048Scene()
-(void)createBase;
-(SKShapeNode *)createBox:(NSArray *)point withColor:(SKColor *)color start:(bool)start;
-(void)createBoxesArray:(SKSpriteNode *)box;
-(int)determineDirection;
-(bool)updateBoxes;
-(void)createNewBox;
-(NSArray *)pt:(int)a :(int)b;
-(bool)transitionBoxFrom:(NSArray *)initial to:(NSArray *)final;
@end

@implementation KC2048Scene{
    CGPoint startPos,endPos;
    NSArray *boxes;
    NSMutableArray *boxesOnScreen;
    bool occupiedBoxes[4][4];
    SKColor *BASEBOXCOLOR;
}

#pragma mark init

-(id)initWithSize:(CGSize)size{
	
	if (self = [super initWithSize:size]){
		
		[self setBackgroundColor:[SKColor colorWithRed:(161/255.0) green:(202/255.0) blue:(241/255.0) alpha:1.0]];
        
        BASEBOXCOLOR = [SKColor colorWithRed:255/255.0 green:198/255.0 blue:41/255.0 alpha:1.0];
        
        boxesOnScreen = [NSMutableArray array];
        
        for (int a=0;a<4;a++)
            for (int b=0;b<4;b++)
                occupiedBoxes[a][b]=0;
            
                
        [self createBase];
        
	}
	
	return self;
    
}

#pragma mark -
#pragma mark update boxes

-(int)determineDirection{
    
    // up down left right
    
    int direction[4] = {0,0,0,0};
    
    if (startPos.x < endPos.x) direction[3]=1;
    else direction[2]=1;
    if (startPos.y < endPos.y) direction[1]=1;
    else direction[0]=1;
    
    if (abs(startPos.x - endPos.x) > abs(startPos.y - endPos.y)) direction[1] = direction[0] = 0;
    else direction[3] = direction[2] = 0;
    
    int i;
    for (i=0;i<4;i++)
        if (direction[i]==1)
            return i;
    
    return -1;
    
}

-(NSArray *)pt:(int)a :(int)b{
    return @[[NSNumber numberWithInt:a],[NSNumber numberWithInt:b]];
}

// move boxes after swipe
-(bool)updateBoxes{
    
    NSMutableArray *newPoints = [NSMutableArray array];
    NSMutableArray *oldPoints = [NSMutableArray array];
    int c=0;
    
    // changes due to swipes
    
    /*
     *  go from swiped direction to its opposite
     *      up: go from top to bottom, etc
     *  save old point
     *  keep moving x,y values until it reaches an edge or another block
     *      update occupiedBoxes also
     *  set that as new point
     */
    
    switch ([self determineDirection]){
            
        // up
        case 0:
            
            for (int y=3;y>=0;y--)
                for (int x=0;x<4;x++)
                    if (occupiedBoxes[x][y]){
                        int a=x, b=y;
                        oldPoints[c] = [self pt:a:b];
                        while (b < 3 && !occupiedBoxes[a][b+1]) {
                            occupiedBoxes[a][b+1]=1;
                            occupiedBoxes[a][b++]=0;
                        }
                        newPoints[c++] = [self pt:a:b];
                    }
            
            break;
            
        // down
        case 1:
            
            for (int y=0;y<4;y++)
                for (int x=0;x<4;x++)
                    if (occupiedBoxes[x][y]){
                        int a=x, b=y;
                        oldPoints[c] = [self pt:a:b];
                        while (b > 0 && !occupiedBoxes[a][b-1]) {
                            occupiedBoxes[a][b-1]=1;
                            occupiedBoxes[a][b--]=0;
                        }
                        newPoints[c++] = [self pt:a:b];
                    }
            
            break;
            
        // left
        case 2:
            
            for (int x=0;x<4;x++)
                for (int y=0;y<4;y++)
                    if (occupiedBoxes[x][y]){
                        int a=x, b=y;
                        oldPoints[c] = [self pt:a:b];
                        while (a > 0 && !occupiedBoxes[a-1][b]) {
                            occupiedBoxes[a-1][b]=1;
                            occupiedBoxes[a--][b]=0;
                        }
                        newPoints[c++] = [self pt:a:b];
                    }
            
            break;
            
        // right
        case 3:
            
            for (int x=3;x>=0;x--)
                for (int y=0;y<4;y++)
                    if (occupiedBoxes[x][y]){
                        int a=x, b=y;
                        oldPoints[c] = [self pt:a:b];
                        while (a < 3 && !occupiedBoxes[a+1][b]) {
                            occupiedBoxes[a+1][b]=1;
                            occupiedBoxes[a++][b]=0;
                        }
                        newPoints[c++] = [self pt:a:b];
                    }
        
            break;
            
        default:
            exit(0);
    }
    
    bool moved = 0;
    
    // transition all boxes
    for (int i=0;i<c;i++)
        if ([newPoints[i][0] intValue] != [oldPoints[i][0] intValue] || [newPoints[i][1] intValue] != [oldPoints[i][1] intValue])
            if ([self transitionBoxFrom:oldPoints[i] to:newPoints[i]])
                moved=1;
    
    return moved;
    
}

#pragma mark -
#pragma mark touches

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    startPos = [[[event allTouches]anyObject] locationInView:self.view];
    
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    endPos = [[[event allTouches]anyObject] locationInView:self.view];
    if ([self updateBoxes])
        [self createNewBox];
    
}

#pragma mark -
#pragma mark create,createNew,transition

// random box creation after each swipe
-(void)createNewBox{
    
    // wait for a certain duration, then
    [self runAction:[SKAction sequence:@[[SKAction waitForDuration:0.3],
                                         [SKAction runBlock:^{
        
        int x,y;
        
        // get coords that aren't taken
        do {
            x = arc4random()%4;
            y = arc4random()%4;
        } while (occupiedBoxes[x][y]==1);
        
        // adds data to boxesOnScreen, && draws the box
        [boxesOnScreen addObject:@[[NSNumber numberWithInt:x],[NSNumber numberWithInt:y],[self createBox:boxes[x][y] withColor:[SKColor blackColor] start:0]]];
        occupiedBoxes[x][y] = 1;
        
    }]]]];
    
}

// draw a box given a point
-(SKShapeNode *)createBox:(NSArray *)point withColor:(SKColor *)color start:(bool)start {
    
    CGRect rect = CGRectMake([point[0] floatValue], [point[1] floatValue], [point[2] floatValue], [point[3] floatValue]);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRoundedRect(path, NULL, rect, 5, 5);
    
    SKShapeNode *box = [SKShapeNode node];
    box.path = path;
    box.fillColor = color;

    if (start){
    
        [self addChild:box];
        
    // fade in
    } else {
        
        box.alpha = 0.0;
        [box runAction:[SKAction fadeInWithDuration:0.4]];
        [self addChild:box];

    }
    
    return box;
    
}

// transitions a box from pt to pt, updating needed variables
-(bool)transitionBoxFrom:(NSArray *)initial to:(NSArray *)final{
    
    int x1 = [initial[0] intValue], y1 = [initial[1] intValue];
    int x2 = [final[0] intValue], y2 = [final[1] intValue];
    
    int c=0;
    
    NSMutableArray *tempBoxesOnScreen = [NSMutableArray arrayWithArray:boxesOnScreen];
    
    // cycle through boxes that are drawn already
    for (NSArray *box in boxesOnScreen){
        
        // if the coords of 'box' match our x1, x2
        if ([box[0] intValue] == x1 && [box[1] intValue] == y1){
            
            CGFloat dx = [boxes[x2][y2][0] floatValue] - [boxes[x1][y1][0] floatValue];
            CGFloat dy = [boxes[x2][y2][1] floatValue] - [boxes[x1][y1][1] floatValue];
            
            SKAction *action = [SKAction moveBy:CGVectorMake(dx, dy) duration:0.3];
            
            // move, then change temp array for new data
            [box[2] runAction:action];
            tempBoxesOnScreen[c] = @[[NSNumber numberWithInt:x2],[NSNumber numberWithInt:y2],box[2]];
            
            boxesOnScreen = [NSMutableArray arrayWithArray:tempBoxesOnScreen];

            return 1;
            
        }
        c+=1;
    }
    
    // should never reach
    exit(0);
    
}

#pragma mark -
#pragma mark use once

// create the x,y,w,h boxes array
-(void)createBoxesArray:(SKSpriteNode *)box{
    
    NSMutableArray *tempBoxes = [NSMutableArray array];
    
    for (int x=box.frame.size.width/8.0;x<box.frame.size.width;x+=box.frame.size.width/4.0){
        NSMutableArray *tempArray = [NSMutableArray array];
        for (int y=box.frame.size.height/8.0;y<box.frame.size.height;y+=box.frame.size.height/4.0){
            [tempArray addObject:@[[NSNumber numberWithFloat:box.position.x-box.frame.size.width/2.0 + (x - box.frame.size.width/5.0/2.0)],[NSNumber numberWithFloat:box.position.y-box.frame.size.height/2.0 + (y - box.frame.size.height/5.0/2.0)],[NSNumber numberWithFloat:box.frame.size.width/5.0],[NSNumber numberWithFloat:box.frame.size.height/5.0]]];
        }
        [tempBoxes addObject:tempArray];
    }
    
    boxes = [NSMutableArray arrayWithArray:tempBoxes];
    
}
// start up
-(void)createBase{
        
    SKSpriteNode *box = [SKSpriteNode spriteNodeWithColor:[SKColor colorWithRed:(255/255.0) green:(143/255.0) blue:(0/255.0) alpha:1] size:CGSizeMake(300, 300)];
    [box setPosition:CGPointMake(self.frame.size.width/2.0,7*self.frame.size.height/18.0)];
    [self addChild:box];
    
    // create the array of boxes
    [self createBoxesArray:box];
    
    for (NSMutableArray *array in boxes)
        for (NSMutableArray *point in array)
            [self createBox:point withColor:BASEBOXCOLOR start:1];
    
    // pick random box, start with that
    [self createNewBox];
    
}

@end
