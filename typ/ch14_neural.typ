#import "../orly-modified.typ": alert

= Neural Networks <ch:14_neural>

```fluxhidden
use crate::rvec::{self, AsRVec as _, RVec, rvec};
use flux_rs::assert;
use flux_rs::attrs::*;
use rand::{Rng, rngs::ThreadRng};
```

Next, lets look at a case study that ties together many of
the different features of Flux that we have seen in the
previous chapters: lets build a small neural network library.
//
This chapter is heavily inspired by this blog post
#footnote[ https://byteblog.medium.com/building-a-simple-neural-network-from-scratch-in-rust-3a7b12ed30a9]
and Michael Nielsen's book on neural networks
#footnote[http://neuralnetworksanddeeplearning.com/chap1.html].


#figure(
  grid(
    columns: 2,
    gutter: 0.2em,
    image("../img/neural-layer-1.png", width: 85%),
    image("../img/neural-layer-2.png", width: 55%)
  ),
  placement: top,
  caption: [A Neural Network Layer with 3 inputs and 4 outputs.]
)
<fig:neural-layer>


== Layers

Per wikipedia, a neural network #footnote[https://en.wikipedia.org/wiki/Neural_network_(machine_learning)]
#quote[
  consists of connected units or nodes called artificial *neurons* ...
  //
  Each artificial neuron receives *signals* from connected
  neurons, then processes them and sends a signal to other
  connected neurons...
  //
  The *output* of each neuron is computed by some non-linear
  *(activation) function* of the totality of its *inputs*...
  //
  The strength of the signal at each connection is determined
  by a *weight*...
  // , which adjusts during the learning process.
  Typically neurons are aggregated into *layers*...
]

Figure @fig:neural-layer illustrates, on the left,
a single neural network layer with 3 _inputs_ and
4 _outputs_.
//
Each output neuron receives a _signal_ from each
of the 3 input neurons, as shown by the edges
from the inputs to the outputs.
//
Furthermore, as shown on the right, each edge has
a _weight_. For example, the `i`#super[th] output neuron
has distinct weights `weight[i][0]` and `weight[i][1]`
and `weight[i][2]` for each of its input neurons.

*Representing Layers* We can represent a layer as a `struct`
with fields for the number of inputs, outputs, weights,
and biases.

```flux
struct Layer {
    num_inputs: usize,
    num_outputs: usize,
    weight: RVec<RVec<f64>>,
    bias: RVec<f64>,
    outputs: RVec<f64>,
}
```

Of course, the plain Rust definition says little about
the `Layer`'s _dimensions_.
//
That is it does not tell us that `weight` is a 2D vector
that stores for each of the `num_outputs`, a vector of
size `num_inputs`, and that `bias` and `outputs` are
vectors of length `num_outputs`.
//
No matter! We _refine_ the `Layer` struct with a detached
#footnote[As described in @ch:10_equality:detached]
specification that makes these relationships explicit.

```flux
#[specs {
    #[refined_by(i: int, o: int)]
    struct Layer {
        num_inputs: usize[i],
        num_outputs: usize[o],
        weight: RVec<RVec<f64>[i]>[o],
        bias: RVec<f64>[o],
        outputs: RVec<f64>[o],
    }
}]
const _: () = ();
```

Lets step through the detached specification.
- First, we declare that the `Layer` struct is
  _refined by_ two `int` indexes `i` and `o`,
  which will represent the input and output
  dimension of the `Layer`;

- Next, we refine the `num_inputs` field as
  `usize[i]` and `num_outputs` field to be
  of type `usize[o]`, meaning that its value
  is equal to the index `i` and `o` respectively,
  and hence, that those fields represent the run-time
  values of their respective dimensions.

- Next, we refine the `weight` field to be a refined
  vector #footnote[As described in @ch:06_vectors]
  of vectors `RVec<RVec<f64>[i]>[o]` indicating that
  for each of the `o` outputs, we have a vector
  of `i` weights, one for each input;

- Finally, we refine the `bias` and `outputs` fields
  to be vectors of length `o`, indicating a single
  bias and output value for each output neuron.

#alert("info", [
*Why Detach?* We could just as easily have written the
above as a regular attached specification, using
attributes on the fields of the `Layer` struct.
//
We chose to use the detached style here purely for
illustration, and because I personally think its
somewhat easier on the eye.
])

== Creating Layers

Next, lets write a constructor for `Layer`s.


*Initializing a Vector*
Since we have to build nested vectors, it will be convenient
to write a helper function that uses a closure to build a vector
of some given size.

```flux
#[spec(fn(n: usize, f:F) -> RVec<A>[n]
       where F: FnMut(usize) -> A)]
fn init<F, A>(n: usize, mut f: F) -> RVec<A>
where
    F: FnMut(usize) -> A,
{
    let mut res = RVec::new();
    for i in 0..n {
        res.push(f(i));
    }
    res
}
```

#alert("success", [
*EXERCISE:* The function below takes as input
a reference to a `RVec` and uses `init` to compute
the `mirror` image of the input, _i.e._, an `RVec`
where the elements are reversed. Can you fix the
specification of `init` so it is accepted?
])

```flux
#[spec(fn(vec: &RVec<T>[@n]) -> RVec<T>[n])]
fn mirror<T: Clone>(vec: &RVec<T>) -> RVec<T> {
    let n = vec.len();
    init(n, |i| vec[n-i-1].clone())
}
```

*Layer Constructor*
//
Our `Layer` constructor will use `init` to create
a randomly generated starting matrix of weights
and biases that will then get adjusted during training.
//
Hooray for closures: we can call `init` with
an outer closure that creates each _output row_ of
the weight matrix, and an inner closure that creates
the _input_ weights for that row.

```flux
impl Layer {
  #[spec(fn(i: usize, o: usize) -> Layer[i, o])]
  fn new(i: usize, o: usize) -> Layer {
    let mut rng = rand::thread_rng();
    Layer {
      num_inputs: i,
      num_outputs: o,
      weight: init(i, |_| init(o, |_| rng.gen_range(-1.0..1.0))),
      bias: init(o, |_| rng.gen_range(-1.0..1.0)),
      outputs: init(o, |_| 0.0),
    }
  }
}
```

#alert("success", [
*EXERCISE:* Looks like the auto-complete snuck in
a bug in definition of `new` above, which, thankfully,
Flux has flagged! Can you spot and fix the problem?
])

== Layer Propagation

A neural layer (and ultimately, network) is, of course,
ultimately a representation of a _function_ that maps
inputs to outputs, for example, to map inputs corresponding
to the pixels of an image to outputs corresponding to
the labels of objects in the image.
//
Thus, each neural layer must implement two key functions:

-  `forward` which _evaluates_ the function by computing the values
   of the outputs given the current values of the inputs, weights,
   and biases; and
- `backward` which _propagates_ the error (or loss) between the
   evaluated output backwards by computing the gradients of the
   weights and biases with respect to the loss, and
   then "trains" the network by adjusting the weights
   and biases to minimize the loss.

Next, let's look at how we might _implement_ these function
using our `Layer` datatype.
//
We will not look at the mathematics of these functions
in any detail, to learn more, I heartily recommend chapters
2 and 3 of  Nielsen's book #footnote[http://neuralnetworksanddeeplearning.com/].

=== Forward Evaluation


In brief, the goal of the `forward` function is to compute
the value of each output neuron `outputs[i]` as the
_weighted sum_ of its input neurons `inputs[i]`,
and return `1` if that sum plus its `bias[i]` --- a threshold ---
is above zero, and `0` otherwise.

$ bold("outputs")[i] := cases(
    1 "if " bold("weights")[i] dot bold("inputs") + bold("bias")[i] > 0,
    0 "otherwise"
) $

The discrete "step" function above discontinuously
leaps from `0` to `1` at the threshold, which gets
in the way of computing gradients during backpropagation.
//
So instead we _smooth_ it out using a _sigmoid_ (logistic) function
//
$ sigma(x) := 1 / (1 + exp(-x)) $
//
which transitions gradually from `0` to `1` as shown below:

#figure(
  image("../img/sigmoid.png", width: 61%),
  caption: [Sigmoid vs. Step Function],
) <fig:sigmoid-step>

Thus, when we put the weighted-sum and sigmoid together, we
get the following formula for computing the i#super[th] output
neuron:

$ bold("outputs")[i] := sigma(bold("weights")[i] dot bold("inputs") + bold("bias")[i]) $ <eq:neural-output>


#alert("success", [
*EXERCISE:* Below is the implementation of a function that computes
the `dot_product` of two vectors. Can you figure out why Flux is complaining and fix the code so it verifies?
])

```flux
fn dot_product2(a: &RVec<f64>, b: &RVec<f64>) -> f64 {
    (0..a.len()).map(|i| (a[i] * b[i])).sum()
}
```

We can now use the implementation of `dot_product`
to transcribe the equation above math into our Rust implementation of `forward`

```flux
impl Layer {
  #[spec(fn(&mut Layer[@l], &RVec<f64>) )]
  fn forward(&mut self, input: &RVec<f64>) {
    (0..self.num_outputs).for_each(|i| {
      let weighted_input = dot_product(&self.weight[i], input);
      self.outputs[i] = sigmoid(weighted_input + self.bias[i])
    })
  }
}
```

#alert("success", [
*EXERCISE:* Flux is unhappy about the implementation of `forward`.
Can you figure out why and add the type specification that lets Flux
verify the code?
])

=== Backward Propagation

Next, lets implement the `backward` propagation function that
takes as input the inputs given to the `Layer` and the _error_
produced by a given Layer (roughly, the difference between the
expected output and the actual output of that layer), and
learning `rate` _hyper-parameter_  that controls the step
size for gradient descent, to

1. _Update_ the weights and biases of the layer to reduce the error, and
1. _Propagate_ the appropriate amount of error to the previous layer.

```flux
impl Layer {
  fn backward(&mut self, inputs: &RVec<f64>, err: &RVec<f64>, rate:f64)
     -> RVec<f64> {
    let mut input_err = rvec![0.0; inputs.len()];
    for i in 0..self.num_outputs {
        for j in 0..self.num_inputs {
            input_err[j] += self.weight[i][j] * err[i];
            self.weight[i][j] -= rate * err[i] * inputs[j];
        }
        self.bias[i] -= rate * err[i];
    }
    input_err
  }
}
```

The code works as follows.

1. First, we initialize the `input_err` vector that corresponds to the `err`
   propagated backwards (to the previous layer);

2. Next, we loop over each output neuron `i`, and iterate over each of
   its inputs `j` to _accumulate_ that input's weighted contribution to
   the `err`, and _update_ `weight[i][j]` (and similarly, `bias[i]`)
   with the gradient `err[i] * inputs[j]` multiplied by the `rate`
   which ensures we subsequently reduce the error;

#alert("success", [
*EXERCISE:* Looks like we forgot to write down the appropriate dimensions
for the input `Layer` and the various input and output vectors, which makes
Flux report errors all over the place. Can you fill them in so the code verifies?
])

== Composing Layers into Networks

A neural _network_ is the composition of multiple _layers_.
//
@fig:neural-network shows a network that maps 3-inputs to 4-outputs,
with three _hidden_ levels in between which respectively 4, 2, and 3
neurons.
//
Put another way, we might say that the network in the figure composes
_four_ `Layer`s shown in blue, green, yellow and orange respectively.
//
In this case, the `Layer`s match up nicely, with the outputs of each
precisely matching the inputs of the next layer.
//
Next, lets see how Flux can help ensure that we only ever construct
networks where the layers snap together perfectly.


#figure(
  image("../img/neural-network.png", width: 100%),
  caption: [A 3-input, 4-output neural network with three hidden levels.]
) <fig:neural-network>



The key idea is to think of _building up_
the network from the right to the left,
starting with the final output layer,
and working our way backwards.

- The _last_ #text(fill:orange)[orange] `Layer[3, 4]`
  corresponds to a `Network` that maps 3 inputs to
  4 outputs (lets call that a `Network[3, 4]`);

- Next, we add the #text(fill: rgb("#d09c18"))[yellow]
  `Layer[2, 3]` that composes with the `Network[3, 4]`
  to give us a `Network[2, 4]`;

- Next, we slap on the #text(fill:rgb("#10932e") )[green] `Layer[4, 2]`
  which connects with the `Network[2, 3]` to give a `Network[4, 4]`;

- Finally, we top it off with the #text(fill: blue)[blue]
  `Layer[3, 4]` that connects with the `Network[4, 4]` to
  give us the final `Network[3, 4]`.

*Refined `Network`s*
//
Lets codify the above intuition by defining a recursive `Network`
that is _refined by_ the number of input and output neurons.

```flux
enum Network {
   #[variant((Layer[@i, @o]) -> Network[i, o])]
   Last(Layer),

   #[variant((Layer[@i, @h], Box<Network[h, @o]>) -> Network[i, o])]
   Next(Layer, Box<Network>),
}
```

Lets consider the two variants of the `Network` enum.

- The `Last` variant takes as input a `Layer[i, o]`
  to construct a `Network[i, o]`, just like the
  #text(fill:orange)[orange] `Layer[3, 4]` yields
  a `Network[3, 4]`;

- The `Next` variant takes as input a `Layer[i, h]`
  which maps `i` _inputs_ to `h` _hidden_ neurons,
  and a `Network[h, o]` which maps those `h` hidden
  neurons to `o` _outputs_, to construct a
  `Network[i, o]` that maps `i` inputs to `o` outputs!

The network in @fig:neural-network can thus be represented as

```flux
#[spec(fn() -> Network[3, 4])]
fn example_network() -> Network {
  let blue = Layer::new(3, 4);
  let green = Layer::new(4, 2);
  let yellow = Layer::new(2, 3);
  let orange = Layer::new(3, 4);
  network![blue, green, yellow, orange]
}
```

where the `network!` macro recursively applies
`Next` and `Last` to build the `Network`.

```flux
#[macro_export]
macro_rules! network {
    ($last:expr) => {
        Network::Last($last)
    };
    ($first:expr, $($rest:expr),+) => {
        Network::Next($first, Box::new(network!($($rest),+)))
    };
}
```

#alert("success", [
*EXERCISE:* Complete the specification and implementation
of a function `Network::new` that takes as input the number
of `inputs`, a slice of `hiddens`, and the number of `outputs`
and returns a `Network` that maps the `inputs` to `outputs`
after passing through the specified hidden layers.
])

```flux
impl Network {
  fn new(inputs: usize, hiddens: &[usize], outputs: usize) -> Network {
    if hidden_sizes.is_empty() {
      Network::Last(Layer::new(input_size, output_size))
    } else {
      todo!()
    }
  }
}
```

When done, the following should create a `Network` like that in @fig:neural-network.

```flux
#[spec(fn() -> Network[3, 4])]
fn test_network() -> Network { Network::new(3, &[4, 2, 3], 4) }
```

== Network Propagation

Finally, lets implement the `forward` and `backward` functions
so that they work over the entire `Network`, thereby allowing us
to do both training and inference.

=== Forward Evaluation

#alert("success", [
*EXERCISE:* The `forward` evaluation recurses on
the `Network`, calling `forward` on each `Layer`
and passing the outputs to the `next` part of the
`Network`, returning the output of the `Last` layer.
Fill in the specification for `forward` so it verifies.
])

```flux
fn forward(&mut self, input: &RVec<f64>) -> RVec<f64> {
  match self {
    Network::Next(layer, next) => {
      layer.forward(input); next.forward(&layer.outputs)
    }
    Network::Last(layer) => {
      layer.forward(input); layer.outputs.clone()
    }
  }
}
```

=== Back Propagation

The _back-propagation_ function assumes we have already done
a `forward` pass, and have the outputs stored in each
`Layer`'s `outputs` field.
//
It then takes as input the `target` or expected output,
computes the `err`or at the last layer, and then propagates
that error backwards through the network, updating the weights
and biases as it goes using the gradients computed at each layer
via its `backward` function.


```flux
fn backward(&mut self, inputs:&RVec<f64>, target:&RVec<f64>, rate:f64)
   -> RVec<f64> {
  match self {
    Network::Last(layer) => {
      let err = (0..layer.num_outputs)
                  .map(|i| layer.outputs[i] - target[i])
                  .collect();
      layer.backward(inputs, &err, rate)
    }
    Network::Next(layer, next) => {
      todo!("exercise: fill this in")
    }
  }
}
```

#alert("success", [
*EXERCISE:* Complete the specification and implementation
of `backward` above so that it recursively propagates the
error all the way to the first layer, by calling `backward`
on each of the intermediate layers.
])

== Summary

#alert("error", [TODO])