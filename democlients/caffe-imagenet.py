import numpy as np
import cbaas
import string
import os
import matplotlib.pyplot as plt
from base64 import b64encode

try:
  caffe.set_gpu_mode()
except:
  print "CPU Mode"

#plt.rcParams['figure.figsize'] = (10, 10)
#plt.rcParams['image.interpolation'] = 'nearest'
#plt.rcParams['image.cmap'] = 'gray'

caffe_root = '/Users/greghale/Programming/caffe/'

import sys
sys.path.insert(0, caffe_root + 'python')

import caffe

if not os.path.isfile(caffe_root + 'models/bvlc_reference_caffenet/bvlc_reference_caffenet.caffemodel'):
    print("Downloading pre-trained CaffeNet model...")
 # TODO I think I dropped some code here.

caffe.set_mode_cpu()
net = caffe.Net(caffe_root + 'models/bvlc_reference_caffenet/deploy.prototxt',
                caffe_root + 'models/bvlc_reference_caffenet/bvlc_reference_caffenet.caffemodel',
                caffe.TEST)

# input preprocessing: 'data' is the name of the input blob == net.inputs[0]
transformer = caffe.io.Transformer({'data': net.blobs['data'].data.shape})
transformer.set_transpose('data', (2,0,1))
transformer.set_mean('data', np.load(caffe_root + 'python/caffe/imagenet/ilsvrc_2012_mean.npy').mean(1).mean(1)) # mean pixel
transformer.set_raw_scale('data', 1)  # the reference model operates on images in [0,255] range instead of [0,1]
transformer.set_channel_swap('data', (2,1,0))  # the reference model has channels in BGR order instead of RGB

imagenet_labels_filename = caffe_root + 'data/ilsvrc12/synset_words.txt'
try:
  labels = np.loadtxt(imagenet_labels_filename, str, delimiter='\t')
except:
  raise Exception("Couldn't load image labels")

def do_work(npimage):
  if npimage.shape[2] == 4:
    npimage = npimage[:,:,0:3]
  print npimage
  print npimage.shape
  # set net to batch size of 50
  net.blobs['data'].reshape(50,3,227,227)

  net.blobs['data'].data[...] = transformer.preprocess('data', npimage)

  #plt.imshow(transformer.deprocess('data', net.blobs['data'].data[0]))

  out = net.forward()
  top_k = net.blobs['prob'].data[0].flatten().argsort()[-1:-6:-1]
  ps = net.blobs['prob'].data[0].flatten()[top_k]
  r = map( lambda x: string.join(x.split()[1:]), labels[top_k] )
  # return str(np.vstack((r,ls)).T.tolist())
  return zip(r,ps.tolist())


if __name__ == "__main__":
  l = cbaas.Listener(domain='greghale.io', on_job=do_work, function_name="labelb", type="TModelImage -> TLabelProbs")
  print "Finished (why?)"
