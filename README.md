SimpleGLK2D
===========

Objective-C GLKit sample for 2D rendering


Usage
-----------

1. Layer

    SWOGLLayer *layer = [SWOGLLayer new];
    [layer loadTextureAtPath:absolutePath];
	layer.depth = -1;

2. Texture

    SWOGLTexture *texture = [SWOGLTexture textureWithImage:image scale:2.0];

3. LayerSet

    SWOGLLayerSet *layerSet = [SWOGLLayerSet new];
    [layerSet addLayer:layer];
    layerSet.depth = -10;
    //The layer's depth becomes -11 if layer's own depth is -1 
    //because layerSet adds its own offset depth for children.
	
	
4. ViewController

    //Subclassing SWOGLViewController, 
    [self.layers addObject:layer];
    //displays a layer content

    [self.layers addObject:layerSet];
    //displays a layerSet content as well
	
5. TextLayer
	
    SWOGLTextLayer *textLayer = [SWOGLTextLayer new];
    textLayer.text = @"some string";
	textColor = GLKVector4Make(0.5, 0.5, 0.5, 1);
	textLayer.font = [UIFont boldSystemFontOfSize:20];
	textLayer.contentSize = CGSizeMake(280, 200);
	[textLayer loadTexture];
	//This draws an image for provided properties and load a texture

6. Animation	
