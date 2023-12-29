#! /bin/bash


function show_help()
{
    echo 'Usage: bash convert [option ...]'
    echo 'Where options are
  --convert         convert model 
  --tflite          produce tflite file
  --quantize        quantize tflite model
  --int8io          make inputs and output of the model int8
  --no-yolo         remove yolo decoding head
  --infer           run inference with converted model
'
}

PARSED_OPTIONS=$(getopt -o "h" -l convert,tflite,quantize,int8io,no-yolo,infer -- "$@")
if [ $? != 0 ] ; then
    show_help
    exit
fi

do_convert='n'
tflite='n'
quantize='n'
int8io='n'
short='n'
infer='n'
EXT=""
FRAMEWORK=""

eval set -- "${PARSED_OPTIONS}"
while : ; do
    case "$1" in
        --convert ) do_convert='y'; shift ;;
        --tflite ) tflite='y' ; shift ;;
        --quantize ) quantize='y' ; shift ;;
        --int8io ) int8io='y' ; shift ;;
        --no-yolo ) short='y' ; shift ;;
        --infer ) infer='y' ; shift ;;
        -h ) show_help ; shift ;;
        -- ) shift ; break ;;
    esac
done

if [ ${tflite} == 'y' ] ; then
    FRAMEWORK="--framework tflite"
    EXT=.tflite
fi
if [ ${quantize} == 'y' ] ; then
    QUANTIZE="--quantize_mode int8 --dataset data/dataset/val2017-local.txt"
    if [ ${int8io} == 'y' ] ; then
        QUANTIZE="${QUANTIZE} --int8io"
    fi
    EXT=-int8.tflite
fi
if [ ${short} == 'y' ] ; then
    NO_YOLO=--short
    EXT=-short${EXT}
fi
IMAGE=data/dataset/coco/images/val2017/000000000785.jpg
IMAGE=data/dataset/coco/images/val2017/000000046872.jpg
IMAGE=data/dataset/coco/images/val2017/000000532058.jpg
IMAGE=data/kite.jpg
IMAGE=data/dog-lb_416.jpg
IMAGE=../darknet/data/att/frame10.png

if [ ${do_convert} == 'y' ] ; then
    python save_model.py --weights ../darknet/wgh/yolov4-tiny.weights --output ./checkpoints/yolov4-tiny-416 --input_size 416 --model yolov4 --tiny ${FRAMEWORK} ${NO_YOLO}

    if [ ${tflite} == 'y' ] ; then
        python convert_tflite.py --weights ./checkpoints/yolov4-tiny-416 --output ./checkpoints/yolov4-tiny-416${EXT} ${QUANTIZE} ${NO_YOLO}
    fi
fi

if [ ${int8io} == 'y' -o ${short} == 'y' ] ; then
    exit
fi

if [ ${infer} == 'y' ] ; then
    python detect.py --weights ./checkpoints/yolov4-tiny-416${EXT} --size 416 --model yolov4 --tiny --image ${IMAGE} ${FRAMEWORK}
fi
