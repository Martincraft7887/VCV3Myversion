function onCreatePost()
    initShader('image', 'image')
    setCameraShader('game', 'image')
    setShaderProperty('image', 'overlayTex', 'images/redpunch.png')
end