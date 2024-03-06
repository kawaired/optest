using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraSetting : MonoBehaviour
{
    public void Awake()
    {
        Camera.main.depthTextureMode=DepthTextureMode.Depth;
    }
}
