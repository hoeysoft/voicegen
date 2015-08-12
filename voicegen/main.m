//
//  main.m
//  voicegen
//
//  Created by KIMYEONGHO on 8/11/15.
//  Copyright (c) 2015 KIMYEONGHO. All rights reserved.
//

#import <Foundation/Foundation.h>

@import AppKit;

NSString* GetVoiceType() {
    if (rand() % 2 == 0)
        return @"com.apple.speech.synthesis.voice.Alex";
    else
        return @"com.apple.speech.synthesis.voice.daniel";
}

NSString* ToFileName(NSString *sentence, NSCharacterSet *charactersToReplace) {
    NSString *filename = [[sentence componentsSeparatedByCharactersInSet:charactersToReplace] componentsJoinedByString:@"_"];
    
    if ([filename length] > 100)
        return [filename substringToIndex:100];
    else
        return filename;
}

NSURL* ToUrl(NSString *filename) {
    return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@.aiff", filename]];
}


@interface FinishWaiter : NSObject<NSSpeechSynthesizerDelegate>
@property BOOL finished;
@end

@implementation FinishWaiter
- (id)init {
    if (self = [super init]) {
        _finished = NO;
    }
    return self;
}

- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender
        didFinishSpeaking:(BOOL)success
{
    _finished = YES;
}
@end

int main(int argc, const char * argv[]) {
    srand((unsigned int)time(NULL));
    @autoreleasepool {
        NSSpeechSynthesizer *synth = [[NSSpeechSynthesizer alloc] init];
        NSCharacterSet *charactersToReplace = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        
        char buffer[1024];
        while (TRUE) {
            printf("vg:");
            fgets(buffer, 1024, stdin);
            
            NSString *line = [NSString stringWithUTF8String:buffer];
            NSString *sentence = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if ([sentence length] == 0) continue;
            
            [synth setVoice:GetVoiceType()];
            NSString *filename = ToFileName(sentence, charactersToReplace);
        
            [pasteboard clearContents];
            NSArray *pbdata = @[[NSString stringWithFormat:@"%@\n[sound:%@.mp3]", sentence, filename]];
            [pasteboard writeObjects:pbdata];

            FinishWaiter *waiter = [[FinishWaiter alloc] init];
            [synth setDelegate:waiter];
            [synth startSpeakingString:sentence toURL:ToUrl(filename)];
            
            // Wait until finished.
            while (![waiter finished] && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:1]]);
            
            system([[NSString stringWithFormat:@"ffmpeg -loglevel quiet -i %@.aiff %@.mp3", filename, filename] UTF8String]);
            system([[NSString stringWithFormat:@"rm %@.aiff", filename] UTF8String]);
            system([[NSString stringWithFormat:@"afplay %@.mp3", filename] UTF8String]);
        }
    }
    return 0;
}
