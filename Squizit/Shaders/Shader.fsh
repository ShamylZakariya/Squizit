//
//  Shader.fsh
//  Squizit
//
//  Created by Shamyl Zakariya on 8/9/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
