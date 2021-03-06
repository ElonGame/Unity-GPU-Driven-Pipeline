﻿using Unity.Collections.LowLevel.Unsafe;
public unsafe struct MStringBuilder
{
    public string str { get; private set; }
    public int capacity { get; private set; }
    public MStringBuilder(int capacity)
    {
        this.capacity = capacity;
        str = new string(' ', capacity);
        fixed (char* c = str)
        {
            int* ptrInt = (int*)c;
            ptrInt[-1] = 0;
        }
    }
    public void Add(string tar)
    {
        Combine(str, tar);
    }
    public void Combine(string a, string b)
    {
        int targetLength = a.Length + b.Length;
        if (targetLength > capacity)
        {
            capacity = targetLength;
            str = new string(' ', capacity);
        }
        else
        {
            fixed (char* c = str)
            {
                int* ptrInt = (int*)c;
                ptrInt[-1] = targetLength;
            }
        }
        fixed (char* dest = str)
        {
            fixed (char* source = a)
            {
                UnsafeUtility.MemCpy(dest, source, a.Length * sizeof(char));
            }
            fixed (char* source = b)
            {
                UnsafeUtility.MemCpy(dest + a.Length, source, b.Length * sizeof(char));
            }
        }
        fixed(char* dest = str)
        {
            int* it = (int*)dest;
            it[-1] = targetLength;
        }
    }
    public void Combine(params string[] strs)
    {
        int targetLength = 0;
        foreach (var i in strs)
        {
            targetLength += i.Length;
        }
        if (targetLength > capacity)
        {
            capacity = targetLength;
            str = new string(' ', capacity);
        }
        else
        {
            fixed (char* c = str)
            {
                int* ptrInt = (int*)c;
                ptrInt[-1] = targetLength;
            }
        }
        int len = 0;
        fixed (char* dest = str)
        {
            foreach (var i in strs)
            {
                fixed (char* source = i)
                {
                    UnsafeUtility.MemCpy(dest + len, source, i.Length * sizeof(char));
                    len += i.Length;
                }
            }
        }

    }
    public void Copy(string source)
    {
        if(source.Length > capacity)
        {
            capacity = source.Length;
            str = new string(' ', capacity);
        }
        fixed(void* dest = str)
        {
            fixed(void* src = source)
            {
                UnsafeUtility.MemCpy(dest, src, source.Length * sizeof(char));
            }
            int* lenPtr = (int*)dest;
            lenPtr[-1] = source.Length;
        }
    }
}
