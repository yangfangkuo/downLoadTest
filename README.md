# downLoadTest
基于af的断点续传及后台下载的demo

先说说断点续传 :

最近重构公司代码,公司需要做文件的断点续传,看了下之前的代码和网上的代码,大家还有好多是使用的NSURLConnection,
![image.png](http://upload-images.jianshu.io/upload_images/5505686-91794ed717110f07.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
,一点一点的拼接data,然后断开连接,再次连接的时候,将本地的data的长度,塞到请求头里面设置range
            [request setValue:rangeString forHTTPHeaderField:@"Range"];
这种的,但是我们的网络请求是封装的AFNetworking的,也发现AFNetworking也有NSURLSessionDownLoadTask,我们就拿过来接着就用了,其实AFNetworking也支持断点续传,而且支持的我感觉还是很完美的.

首先,我们创建一个管理下载的manager及下载的配置,注意那个后台任务的backgroundSessionConfigurationWithIdentifier是要确定的,要后台下载的时候使用

![image.png](http://upload-images.jianshu.io/upload_images/5505686-35eb3cdbc402bc18.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

![image.png](http://upload-images.jianshu.io/upload_images/5505686-4b800335ea4a35bc.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


注意代码中的一个AF的通知监听,特别重要,后台下载的回调及下载成功失败的回调,都是在这个通知里面(其实是AFNetworking封装了,把回调信息都是通过通知传递的,在这里真的佩服AFNetworking作者,把通知用的这么出神入化,我是在这里重新对通知的认知提高了一个大的阶段,这里只是上了一点发送通知的地方,通知的userInfo带了很多东西,详细的大家可以看下AF的源码)

AFURLSessionManager开始一个下载的时候,有两个方法,分别是开始下载(重头下载),继续下载(需要传入一个resumeData)
![image.png](http://upload-images.jianshu.io/upload_images/5505686-8a5b5aadc71e4c3c.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
看方法名,作者就给我们做了断点续传的功能

介绍完这两个方法名,我们介绍下第一个方法是怎么使用,和第二个是什么使用的,并且resumeData是在哪里获取的

当我们需要下载的时候,主动去调用downloadTaskWithRequest方法,根据下载地址url,去判断本地是否有resumeData,这个类似SDWebImage的实现,我们自己去维护这个对应关系,可以存到本地一个plist文件里面,键值对对应 url:resumeData ,然后开始下载的时候,去判断当前是否存在这个url:resumeData,存在的话,看一下长度是否大于零(当用户开始下载的时候,如果什么都没下载到,就终端下载,resumeData是nil,如果直接写入plist是会崩溃的,我们可以写一个空字符串,虽然不是一个类型,但是length都可以使用,不会太影响),大于零,就使用resumeData调用downloadTaskWithResumeData这个方法,然后去开始我们的任务

![image.png](http://upload-images.jianshu.io/upload_images/5505686-144c2758036e94ed.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

上面是两个基本的方法介绍,这里介绍一下那个ResumeData在哪里获取,什么时候获取,
还是上面提到的那个通知(是在NSURLSessionTaskDelegate这个协议里面的- (void)URLSession:(__unused NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error 这个方法发出了的,其实downLoadTask的成功,失败,中断都会调用这个方法),所以,我们需要去刚刚那个通知里面去看看到底都传过来什么.

![image.png](http://upload-images.jianshu.io/upload_images/5505686-3983d26b6978558b.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

拿到了这个ResumeData,大家就可以区分使用什么时候开始断点续传,什么时候重新下载了

大家可以主动去将task 提前结束来触发那个通知,一般不允许蜂窝下载的时候,会用到这个方法

![image.png](http://upload-images.jianshu.io/upload_images/5505686-724f0fbe325ca5f3.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)



后台下载 : 

  后台下载呢,其实上面初始化那个manger的时候,配置那个后台配置的时候,已经实现了后台下载的过程,你可以尝试下,你调回前台,你的下载也在继续,只是这个时候,你的session被操作系统接过去了,操作系统去管理了,一旦你下载完成,会通知你(如果你的app还活着的时候),那么你的app死了的时候怎么办呢,操作系统会给你留着,持有者,等你的app再次复活的时候,并且再次创建NSURLSessionConfiguration,有后台任务,并且后台的backgroundSessionConfigurationWithIdentifier一致的话,操作系统会去调用你的原来的NSURLSessionTaskDelegate代理中的task的didCompleteWithError的方法,由于我们的使用的是AF封装的,所以那个代理被AF接到并且通过通知处理了,所以还是会在我们之前监听的那个通知里面,和我们app活着的时候一样一样的,去发送那个AFNetworkingTaskDidCompleteNotification的通知,在这里 我们原来的处理逻辑不需要改变,

上面讲的是我们进入后台,app慢慢的被系统 杀死 或者没杀死的时候,那么,如果我正在下载着,app崩溃,或者被用户手动强退怎么办? 经过验证,其实是一样的,出现这个情况后,操作系统监听到被杀死或者被中断,也会帮我们持有这个session,然后把崩溃的一瞬间的ResumeData存着,等待我们再次创建相同后缀的session,那时候在调用回调---->af再发通知---->我们再存起来.
![image.png](http://upload-images.jianshu.io/upload_images/5505686-fa4e232c9598ac55.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

讲了这么多,大家是不是特别好奇,AF的resumeData到底是什么?
其实resumeData是一个data类型,大家可以转成字符串,看一下里面的内容
他的本质是一个xml文件
AF在下载的时候,会将文件先下载到沙盒目录下的temp文件夹中,生成一个后缀为tmp的文件,等我们下载完的时候,会将文件处理,然后移动到我们下载时设置的路径下,这样,我们的下载任务就完成了,
![image.png](http://upload-images.jianshu.io/upload_images/5505686-7c11d8c1d0499e30.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
在上面的xml文件中,大家可以看到下载的url,当前接受的文件大小,第几次下载,还有临时文件名等信息,其实本质还是万变不离其宗,但是感觉这样用起来挺好的,既然用了AF了,就用到底吧,这样 ,我们基本的断点续传和后台下载是说完了,有错误希望大家指出,共同进步,谢谢
对了,参考过一个同学关于后台下载的讲解,大家可以看一下
参考文章 http://www.jianshu.com/p/1211cf99dfc3

对大家致敬,感谢
