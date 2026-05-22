#!/usr/bin/env clojure
(import '[java.math BigInteger]
        '[java.util Locale])

(defn trailing-zeroes [n]
  (loop [x (long n) z 0]
    (if (zero? x)
      z
      (let [q (quot x 5)]
        (recur q (+ z q))))))

(def MAX-NATIVE 9000000000000000000)

(defn native-chunks [^long n]
  (loop [i 1
         p 1
         chunks (transient [])]
    (if (> i n)
      (persistent! (if (= p 1) chunks (conj! chunks (BigInteger/valueOf p))))
      (if (<= p (quot MAX-NATIVE i))
        (recur (inc i) (* p i) chunks)
        (recur i 1 (conj! chunks (BigInteger/valueOf p)))))))

(defn pair-reduce [xs]
  (loop [v (vec xs)]
    (let [c (count v)]
      (cond
        (= c 0) BigInteger/ONE
        (= c 1) (v 0)
        :else
        (recur
          (loop [i 0 out (transient [])]
            (cond
              (>= i c) (persistent! out)
              (= i (dec c)) (persistent! (conj! out (v i)))
              :else
              (let [a ^BigInteger (v i)
                    b ^BigInteger (v (inc i))]
                (recur (+ i 2) (conj! out (.multiply a b)))))))))))

(defn fact [^long n]
  (pair-reduce (native-chunks n)))

(let [n (long (if (seq *command-line-args*)
                (Long/parseLong (first *command-line-args*))
                99999))
      t0 (System/nanoTime)
      f (fact n)
      t1 (System/nanoTime)
      ms (/ (double (- t1 t0)) 1000000.0)
      digits (count (.toString ^BigInteger f))
      z (trailing-zeroes n)
      line (String/format Locale/ROOT
                          "Clojure|%.3f|%d|%d|BigInteger packed native chunks tree%n"
                          (to-array [ms digits z]))]
  (print line))
