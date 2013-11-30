//
//  main.m
//  imagecrunch
//
//  Created by Thomas Boutell on 11/30/13.
//  Copyright (c) 2013 Thomas Boutell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#define VERSION "1.0.0"

void save(CGImageRef imageRef, NSString *path);
void usage();

int main(int argc, const char * argv[])
{
  // imagecrunch image.png -size 50 50 -crop 0 0 100 100 -write imagesmall.png -size...
  
  @autoreleasepool {
    double width, height, cropX, cropY, cropW, cropH;
    int size = 0;
    int crop = 0;
    
    if (argc < 2) {
      usage();
    }
    
    if (!strcmp(argv[1], "-info")) {
      // Really basic support for obtaining information about the image
      // in JSON format
      
      // Use CGImageSource to ensure accurate information about the EXIF orientation
      // property
      
      if (argc != 3) {
        usage();
      }
      NSData *data = [NSData dataWithContentsOfFile:[NSString stringWithUTF8String:argv[2]]];
      
      // Use magic number to identify file type, sigh
      unsigned char magic[8];
      char *extension;
      [data getBytes:magic length: 8];
      
      unsigned char pngMagic[] = {
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A
      };
      if (!memcmp(magic, pngMagic, 8)) {
        extension = "png";
      }
      unsigned char gifMagic[] = {
        0x47, 0x49, 0x46, 0x38, 0x39, 0x61
      };
      if (!memcmp(magic, gifMagic, 6)) {
        extension = "gif";
      }
      unsigned char gifMagic2[] = {
        0x47, 0x49, 0x46, 0x38, 0x37, 0x61
      };
      if (!memcmp(magic, gifMagic2, 6)) {
        extension = "gif";
      }
      unsigned char jpgMagic[] = {
        0xFF, 0xD8
      };
      if (!memcmp(magic, jpgMagic, 2)) {
        extension = "jpg";
      }
      if (!extension) {
        fprintf(stderr, "Unrecognized file type or corrupt file\n\n");
        usage();
      }
      
      CGImageSourceRef imageSource = CGImageSourceCreateWithData ((__bridge CFDataRef) data, NULL);
      
      CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
      
      int width, height, originalWidth, originalHeight;
      CFNumberGetValue(CFDictionaryGetValue(properties, @"PixelWidth"), kCFNumberIntType, &originalWidth);
      CFNumberGetValue(CFDictionaryGetValue(properties, @"PixelHeight"), kCFNumberIntType, &originalHeight);
      int orientation = 0;
      
      char *orientations[] = {
        "Undefined", "TopLeft", "TopRight", "BottomRight", "BottomLeft", "LeftTop", "RightTop", "RightBottom", "LeftBottom"
      };
      
      CFNumberRef orientationRef = CFDictionaryGetValue(properties, @"Orientation");
      if (orientationRef) {
        CFNumberGetValue(orientationRef, kCFNumberIntType, &orientation);
      }
      
      width = originalWidth;
      height = originalHeight;
      if ((orientation == 5) || (orientation == 6) || (orientation == 7) || (orientation == 8)) {
        width = originalHeight;
        height = originalWidth;
      }

      printf("{\n");
      printf("  \"extension\": \"%s\",\n", extension);
      printf("  \"width\": %d,\n", width);
      printf("  \"height\": %d,\n", height);
      printf("  \"originalWidth\": %d,\n", originalWidth);
      printf("  \"originalHeight\": %d,\n", originalHeight);
      printf("  \"orientationCode\": %d,\n", orientation);
      printf("  \"orientation\": \"%s\"\n", orientations[orientation]);
      printf("}\n");
      return 0;
    }

    // Conversion, cropping and scaling

    NSData *data = [NSData dataWithContentsOfFile:[NSString stringWithUTF8String:argv[1]]];

    NSBitmapImageRep *rep = [NSBitmapImageRep imageRepWithData: data];

    CGImageRef original = [rep CGImage];
    
    int i = 2;
    while (i < argc) {
      if (!strcmp(argv[i], "-size")) {
        size = 1;
        i++;
        if (i == argc)
        {
          usage();
        }
        width = atof(argv[i]);
        i++;
        if (i == argc)
        {
          usage();
        }
        height = atof(argv[i]);
        i++;
        continue;
      }
      if (!strcmp(argv[i], "-crop")) {
        crop = 1;
        i++;
        if (i == argc)
        {
          usage();
        }
        cropX = atof(argv[i]);
        i++;
        if (i == argc)
        {
          usage();
        }
        cropY = atof(argv[i]);
        i++;
        if (i == argc)
        {
          usage();
        }
        cropW = atof(argv[i]);
        i++;
        if (i == argc)
        {
          usage();
        }
        cropH = atof(argv[i]);
        i++;
        if (i == argc)
        {
          usage();
        }
        continue;
      }
      if (!strcmp(argv[i], "-write")) {
        i++;
        if (i == argc)
        {
          usage();
        }
        const char *name = argv[i];
        i++;

        if (crop) {
          original = CGImageCreateWithImageInRect(original, CGRectMake(cropX, cropY, cropW, cropH));
          // Don't do the crop over and over getting smaller and smaller...
          crop = false;
        }

        if (!size) {
          width = CGImageGetWidth(original);
          height = CGImageGetHeight(original);
        }
        
        // Never distort, never enlarge
        double fWidth, fHeight;
        fWidth = width;
        fHeight = ((double) CGImageGetHeight(original)) / ((double) CGImageGetWidth(original)) * fWidth;
        if (fHeight > height) {
          fHeight = height;
          fWidth = ((double) CGImageGetWidth(original)) / ((double) CGImageGetHeight(original)) * fHeight;
        }
        if (fHeight > CGImageGetHeight(original)) {
          fHeight = CGImageGetHeight(original);
          fWidth = ((double) CGImageGetWidth(original)) / ((double) CGImageGetHeight(original)) * fHeight;
        }
        if (fWidth > CGImageGetWidth(original)) {
          fWidth = CGImageGetWidth(original);
          fHeight = ((double) CGImageGetHeight(original)) / ((double) CGImageGetWidth(original)) * fWidth;
        }

        CGContextRef ref = CGBitmapContextCreate( NULL, fWidth, fHeight, 8, 0, CGColorSpaceCreateDeviceRGB(), (CGBitmapInfo) kCGImageAlphaNoneSkipFirst);
        
        CGContextDrawImage(ref, CGRectMake(0, 0, fWidth, fHeight), original);
        
        save(CGBitmapContextCreateImage(ref), [NSString stringWithUTF8String:name]);
        continue;
      }
      usage();
    }
  }
    return 0;
}

void save(CGImageRef imageRef, NSString *path)
{
  CFStringRef type;
  if ([path hasSuffix: @".jpg"]) {
    type = kUTTypeJPEG;
  } else if ([path hasSuffix: @".gif"]) {
    type = kUTTypeGIF;
  } else if ([path hasSuffix: @".png"]) {
    type = kUTTypePNG;
  } else {
    return usage();
  }
  NSURL *fileURL = [NSURL fileURLWithPath:path];
  CGImageDestinationRef dr = CGImageDestinationCreateWithURL((__bridge CFURLRef)fileURL, type, 1, NULL);
  
  CGImageDestinationAddImage(dr, imageRef, NULL);
  CGImageDestinationFinalize(dr);
  
  CFRelease(dr);
}

void usage()
{
  fprintf(stderr, "imagecrunch %s\n\n", VERSION);
  fprintf(stderr, "Usage: imagecrunch image.png -size 50 50 -crop 0 0 100 100 -write imagesmall.png -size...\n");
  fprintf(stderr, "-crop may only be used once. Output filenames must be .png, .jpg or .gif.\n");
  fprintf(stderr, "Cropping coordinates are in the coordinate space of the original file.\n");
  fprintf(stderr, "Images are never distorted and never enlarged, so the width and height for\n");
  fprintf(stderr, "-size are maximums.\n");
  fprintf(stderr, "\n\n");
  fprintf(stderr, "OR:\n\n");
  fprintf(stderr, "imagecrunch -info filename.png (or .jpg or .gif)\n");
  exit(1);
}