//
//  SVGAVideoEntity+PTEX.m
//  PooTools_Example
//
//  Created by 邓杰豪 on 21/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

#import "SVGAVideoEntity+PTEX.h"

@implementation SVGAVideoEntity (Extension)

- (NSInteger)minFrame {
    return 0;
}

- (NSInteger)maxFrame {
    int frames = self.frames;
    return frames > 1 ? (frames - 1) : 0;
}

- (NSTimeInterval)duration {
    int frames = self.frames;
    int fps = self.FPS;
    if (frames > 0 && fps > 0) {
        return (NSTimeInterval)frames / (NSTimeInterval)fps;
    }
    return 0;
}

- (SVGAVideoEntityError)entityError {
    if (self.videoSize.width <= 0 || self.videoSize.height <= 0) {
        return SVGAVideoEntityError_ZeroVideoSize;
    }
    else if (self.FPS == 0) {
        return SVGAVideoEntityError_ZeroFPS;
    }
    else if (self.frames == 0) {
        return SVGAVideoEntityError_ZeroFrames;
    }
    return SVGAVideoEntityError_None;
}

@end
