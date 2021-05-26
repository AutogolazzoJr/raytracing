uniform sampler2D texture1;
uniform sampler2D texture2;
uniform sampler2D texture3;
uniform sampler2D texture4;
uniform sampler2D texture5;
uniform sampler2D texture6;
uniform sampler2D texture7;
uniform sampler2D texture8;
uniform sampler2D texture9;
uniform sampler2D texture10;

vec4 textureAt(int textureID, vec2 texCoord) {
	switch(textureID) {
	case 1:
		return texture(texture1, texCoord);
	case 2:
		return texture(texture2, texCoord);
	case 3:
		return texture(texture3, texCoord);
	case 4:
		return texture(texture4, texCoord);
	case 5:
		return texture(texture5, texCoord);
	case 6:
		return texture(texture6, texCoord);
	case 7:
		return texture(texture7, texCoord);
	case 8:
		return texture(texture8, texCoord);
	case 9:
		return texture(texture9, texCoord);
	case 10:
		return texture(texture10, texCoord);
	}
}