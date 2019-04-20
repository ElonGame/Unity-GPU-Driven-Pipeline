﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using System.Reflection;
using static Unity.Mathematics.math;
using MPipeline;
using static Unity.Collections.LowLevel.Unsafe.UnsafeUtility;
using Unity.Mathematics;
using Unity.Collections;
using Random = UnityEngine.Random;
public unsafe class Test : MonoBehaviour
{
    public UnityEngine.UI.Text txt;
    private float deltaAcc = 0;
    private int count = 0;
    private struct TestEqual : IFunction<int, int, bool>
    {
        public bool Run(ref int a, ref int b)
        {
            return a == b;
        }
    }
    private void Update()
    {
        deltaAcc += Time.deltaTime;
        count++;
        if (count >= 20)
        {
            deltaAcc /= count;
            txt.text = (deltaAcc * 1000).ToString();
            count = 0;
            deltaAcc = 0;
        }
    }
}
