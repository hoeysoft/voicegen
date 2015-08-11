//
//  main.m
//  voicegen
//
//  Created by KIMYEONGHO on 8/11/15.
//  Copyright (c) 2015 KIMYEONGHO. All rights reserved.
//

#import <Foundation/Foundation.h>

@import AppKit;


NSString* ToFileName(NSString *sentence, NSCharacterSet *charactersToReplace) {
    return [[sentence componentsSeparatedByCharactersInSet:charactersToReplace] componentsJoinedByString:@"_"];
}

NSURL* ToUrl(NSString *filename) {
    return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@.aiff", filename]];
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSFileHandle *input = [NSFileHandle fileHandleWithStandardInput];
        
        NSSpeechSynthesizer *synth = [[NSSpeechSynthesizer alloc] init];
        [synth setVoice:@"com.apple.speech.synthesis.voice.daniel"];
        
        NSCharacterSet *charactersToReplace = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        
        while (TRUE) {
            NSData* data = [input availableData];
            
            if(data == nil) continue;
            
            NSString *line = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSString *sentence = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if ([sentence length] == 0) continue;
            
            NSString *filename = ToFileName(sentence, charactersToReplace);
            
            [synth startSpeakingString:sentence toURL:ToUrl(filename)];
            
            while ([synth isSpeaking]) {
                [NSThread sleepForTimeInterval:0.1f];
            }
            [synth stopSpeaking];
        
            system([[NSString stringWithFormat:@"ffmpeg -loglevel quiet -i %@.aiff %@.mp3", filename, filename] UTF8String]);
            system([[NSString stringWithFormat:@"rm %@.aiff", filename] UTF8String]);
            system([[NSString stringWithFormat:@"afplay %@.mp3", filename] UTF8String]);
            
            [pasteboard clearContents];
            NSArray *pbdata = @[[NSString stringWithFormat:@"[sound:%@.mp3]", filename]];
            [pasteboard writeObjects:pbdata];
        }
    }
    return 0;
}
