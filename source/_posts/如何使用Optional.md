---
title: 如何使用Optional
date: 2024-03-10 19:15:23
tags: [How to coding?]
---

一个好的抽象，应该具备以下几个特点

1. 做正确的事很简单，做错误的事很困难。

2. 隐藏了某些细节，让上层关注更重要的部分

<!--more-->

自从编程语言可以将内存地址抽象为符号开始，程序员就备受备受空指针的折磨。每年因为空指针引起的线上事故可以绕地球两圈半。来看一个例子

我们定义了一个```Car```、一个```Factory```、和一个```TeslaFactory```（用来生产```Car```）。面向接口编程，一切都非常好

```JAVA
/**
 * 至于人类为什么会发明 record，后续博客也会聊到
 **/
public record Car(String color, Integer size) {}

public interface Factory {
    Car make();
}

public class TeslaFactory implements Factory {
    @Override
    public Car make() {
        return new Car("black", 100);
    }
}

public class Main {
    public static void main(String[] args) {
        Factory factory = new TeslaFactory();
        Car car = factory.make();
        // car's color is black
        System.out.println("car's color is " + car.color());
    }
}

```

让我们观察以上代码，```Car make();```对于返回值没有任何表态。当然在系统架构时，Factory Leader会拍着胸脯表示，这个方法会返回一辆小汽车。

一位久经沙场的架构师会懂得，人类的约定是最不靠谱的，当然这里没有人知道这一点。在系统上线一星期后，```TeslaFactory```在预期外的返回了一个**null**

```java
public class TeslaFactory implements Factory {
    @Override
    public Car make() {
        if (new Random().nextBoolean()) {
            return null;
        }
        return new Car("black", 100);
    }
}
```

> 让我们通过一个随机数来mock某些异常事件。在现实中，这个随机数更可能是用户没有按照预想来输入、代码执行了某些异常分支，数据库中当前行的某些字段为空

很显然，当前系统会出现严重问题，一连串的```NullPointerException```出现在了监控中，轻则挂掉当前工作线程，重则系统宕机，程序员们加班加点处理事故，月末绩效清零。

当然程序员们解决问题的思路也很简单，空指针问题向来容易解决

```java
public class Main {
    public static void main(String[] args) {
        Factory factory = new TeslaFactory();
        Car car = factory.make();
        if (car != null) {
            System.out.println("car's color is " + car.color());
        }
    }
}
```

在使用代表内存地址的符号之前，首先进行一次空判定，如果不为空，再对它执行某些操作。

这个处理思路可以解决所有空指针问题。修复后的代码上线，系统继续稳定运行，一切都那么美好。直到那一天，那一天系统中增加了对car的操作，

```java
public class Main {
    public static void main(String[] args) {
        Factory factory = new TeslaFactory();
        Car car = factory.make();
        if (car != null) {
            System.out.println("car's color is " + car.color());
        }
        
        // balabala
        // yahoyaho

        System.out.println("car's size is " + car.size());
    }
}
```

工作中总会遇到这种事。结果也很明显，系统再次陷于```NullPointerException```地狱。

为了不重蹈覆辙，这次架构师升级了接口定义

```java
public interface Factory {
    /**
     * 
     * @return Nullable
     */
    Car make();
}
```

或者更强力的定义

```java
public interface Factory {
    @Nullable
    Car make();
}
```

架构师做了极大的努力，想让使用接口的人避免再次犯空指针问题。That's good, but it's not good enough。如果程序员们没有完成读完接口定义，或者没有看过后续的release note，或者还是忘记了，那么空指针问题仍然像一个幽灵，徘徊在整个系统里。

**做正确的事很简单，做错误的事很困难。**

在经历了无数次空指针地狱后，架构师痛定思痛，开始使用Optional改造系统

```java
public interface Factory {
    Optional<Car> make();
}
```

与上面接口定义最不一样的地方，接口返回的不再是```Car```，而是```Optional<Car>```。继续来看一下```TeslaFactory```实现

```java
public class TeslaFactory implements Factory {
    @Override
    public Optional<Car> make() {
        if (new Random().nextBoolean()) {
            return Optional.empty();
        }
        return Optional.of(new Car("black", 100));
    }
}
```

最后来看一下使用

```java
public class Main {
    public static void main(String[] args) {
        Factory factory = new TeslaFactory();
        Optional<Car> carOptional = factory.make();
        carOptional.ifPresent(car -> {
            System.out.println("car's color is " + car.color());
        });
        // balabala
        carOptional.ifPresent(car -> {
            System.out.println("car's size is " + car.size());
        });
    }
}
```

自此，所有Factory的调用都不会触发空指针地狱了，世界和平，可喜可贺。

```Optional```做了什么？

```Optional```是一个容器，看到它就会意识到其中的值可能为空。如果一个方法可能返回空值，那么就使用```Optional```对返回值进行包装，只有经历过空判断后，调用方才能获取到预期的对象。也就避免了可能出现的空指针异常。

当然，```if (obj != null)```也可以做到相同的事，也可以避免空指针异常。但是比起手动判断，```Optional```有着相当显著的优势

1. 显式声明Nullable。比起注释、注解或代码推演，接口直接返回```Optional```让用户在无论何时都会执行空判定。从源代码层面杜绝可能出现的空指针问题

2. 更高层级的抽象。对于使用方来说，```if (obj != null)```是过程式的代码，过程式代码更加难以复用。将而```Optional```将针对Nullable对象的操作转换为对应的函数调用，用户可以在此之上实现更加抽象、更加优雅的代码

以上。就算```Optional```已经是很简洁的工具，但是依然有着优雅的使用和坏的使用。

```java

public class Main {
    public static void main(String[] args) {
        Factory factory = new TeslaFactory();
        Optional<Car> carOptional = factory.make();
        // good
        carOptional.ifPresent(car -> {
            System.out.println("car's color is " + car.color());
        });
        // bad
        if (carOptional.isPresent()) {
            Car car = carOptional.get();
            System.out.println("car's size is " + car.size());
        }
    }
}

```

如果使用```Optional.isPresent()```，那么与使用```if (obj != null)```则没有太大的差别，代码会陷入 *过程式的地狱*，变得又臭又长。

**隐藏了某些细节，让上层关注更重要的部分。**

更好的方法是通过函数式调用，让判空操作隐藏在```Optional```内部。关注 **操作**。而非 **是否为空** 这种细节。强迫程序员思考如何拆分复用代码函数，让代码更加抽象和健壮。

这便是为什么我们要使用```Optional```，以及如何更好的使用```Optional```。

如果仍然不理解```Optional```比起```if (obj != null)```好在哪里，后续还有其他博客，继续用java为例介绍**抽象**的强大和必要性（说实话笔者也觉得```Optional```有点简单了，后面的更重量级）

> 如果解决不了问题，就加一层
