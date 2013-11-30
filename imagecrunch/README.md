# imagecrunch

`imagecrunch` is a simple, blazing fast tool for rendering an image file at many
sizes. `imagecrunch` can also crop, convert between formats and automatically
rotate photos so that they will face the right way in all web browsers.

`imagecrunch` relies on native MacOS X APIs, which is why it is less than 300 lines of code and the binary is about 15K. On Linux or Windows we suggest using Imagemagick, which can do much, much more, although imagecrunch is a lot faster.

## Usage

Let's scale an image to three different sizes with one command:

    imagecrunch original.jpg -size 300 500 -write small.jpg -size 500 700 -write medium.jpg -size 1200 800 -write large.jpg

Images are *never enlarged* and *never distorted*. If you specify `-size 300 500` you will get the largest image that fits in that box *without changing the aspect ratio*, and *without enlarging the original*.

(Both would look terrible, so we don't do them.)

Now let's crop to fetch Jane's head from the team photo:

    imagecrunch team.jpg -crop 350 300 100 100 -write jane.jpg

The arguments to `-crop` are: `x`, `y`, `width`, `height`.

You can use `-size` and `-write` as many times as you want. You can only use `-crop` once. This is a good thing: crop the original the way you want it, then output the result scaled to lots of sizes.

Oh yes, we can get information about a file:

    imagecrunch -info flower.jpg

Might generate this output:

    {
      "extension": "jpg",
      "width": 1936,
      "height": 2592,
      "originalWidth": 2592,
      "originalHeight": 1936,
      "orientationCode": 6,
      "orientation": "RightTop"
    }

Yes, it's valid JSON. Just call JSON.parse() in your scripting language of choice.

`extension` always tells the truth: it's based on what is in the file, not the original file extension, which could be a lie.

`width` and `height` are the size of the image after orientation is taken into account. `originalWidth` and `originalHeight` are the size of the image before orientation. `orientationCode` and `orientation` are... for people who get really excited about EXIF. For everyone else, just know that we automatically rotate images when we load them, so all the images you `-write` will always face the right way in every browser.

## Changelog

1.0.0: initial release.

## Credits

Created at [P'unk Avenue](http://punkave.com/).


## Questions

[Create issues on github](http://punkave.com/imagecrunch).

