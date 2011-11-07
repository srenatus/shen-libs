\* Copyright 2010-2011 Ramil Farkhshatov

defstruct is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

defstruct is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with defstruct.  If not, see <http://www.gnu.org/licenses/>.

## Description

Module system is a convenient tool for managing libraries.

## Usage syntax

* `(use-modules [mod1 mod2 ...])` 
loads given modules with all their dependencies. Any module already loaded
won't be loaded twice.

* `(reload-module mod1)`
reloads given module.

* `(list-modules all)`
returns a list of known modules.

* `(list-modules loaded)`
returns a list of loaded modules.

* `(dump-module mod language implementation target-dir)`
dumps module `mod` and its dependencies to given implementation of given
language to supplied directory.

* `(set *modules-paths* [dir1 dir2])`
sets list of directories where modules are searched.

## Module definition

Sample contents of `mod1/module.shen` where `mod1` is module name:

  (register-module [[name: mod1]
                    [load: "file1" "file2"]
                    [depends: mod3 mod4]])

*\

(package module-
         [name depends load load-fn unload-fn dump dump-fn path loaded all
          *modules-paths* find-module use-modules dump-module register-module
          reload-module list-modules load-native dump-native module-str-list
          module-sym module-str module-load-fn module-dump-fn module-deps]

(synonyms load-fn (string --> boolean)
          dump-fn (symbol --> (symbol --> (string --> boolean))))

(datatype module-desc
  X : symbol;
  ==============================
  [name : X] : module-desc-item;

  X : (list symbol);
  ===================================
  [depends : | X] : module-desc-item;

  X : (list string);
  =============================
  [load : | X] : module-desc-item;

  X : (list string);
  =============================
  [dump : | X] : module-desc-item;

  X : symbol;
  _________________________________
  [load-fn : X] : module-desc-item;

  X : load-fn >> P;
  ______________________________________
  [load-fn : X] : module-desc-item >> P;

  X : symbol;
  ___________________________________
  [unload-fn : X] : module-desc-item;

  X : load-fn >> P;
  ________________________________________
  [unload-fn : X] : module-desc-item >> P;

  X : symbol;
  _________________________________
  [dump-fn : X] : module-desc-item;

  X : dump-fn >> P;
  ______________________________________
  [dump-fn : X] : module-desc-item >> P;

  if (not (element? X [name depends load dump load-fn unload-fn dump-fn]))
  X : symbol; Y : string;
  ===========================
  [X : Y] : module-desc-item;

  __________________
  [] : module-desc;

  Y : module-desc-item; F : module-desc;
  ======================================
  [Y | F] : module-desc;

  X : module-desc;
  __________________________
  (reverse X) : module-desc;

  X : module-desc; Y : module-desc;
  _________________________________
  (append X Y) : module-desc;

  X : symbol;
  ____________________________________
  (module-fn X) : (string --> boolean);)

(datatype module-types

  ___________
  [] : entry;

  X : symbol; F : module-desc;
  ============================
  [X | F] : entry;

  _________________________________
  (value *modules*) : (list entry);

  X : (list entry);
  _________________________________
  (set *modules* X) : (list entry);

  ________________________________________
  (value *loaded-modules*) : (list symbol);

  X : (list symbol);
  ________________________________________
  (set *loaded-modules* X) : (list symbol);

  ________________________________________
  (value *modules-paths*) : (list string);

  X : (list string);
  ________________________________________
  (set *modules-paths* X) : (list string);

  __________________________________
  (value *home-directory*) : string;
  )

(set *loaded-modules* [])
(set *modules* [])
(set *modules-paths* [])

(define module-loaded?
  {symbol --> boolean}
  M -> (element? M (value *loaded-modules*)))

(define module-deps
  {module-desc --> (list symbol)}
  [] -> []
  [[depends : | M] | R] -> M
  [_ | R] -> (module-deps R))

(define module-str-list
  {symbol --> module-desc --> (list string)}
  _ [] -> []
  load [[load : | F] | _] -> F
  dump [[dump : | F] | _] -> F
  T [_ | R] -> (module-str-list T R))

(define module-str
  {symbol --> module-desc --> string}
  _ [] -> ""
  K [[K : F] | _] -> F
  K [_ | R] -> (module-str K R))

(define module-sym
  {symbol --> module-desc --> symbol}
  _ [] -> null
  name [[name : F] | _] -> F
  T [_ | R] -> (module-sym T R))

(define null-load-fn
  {string --> boolean}
  _ -> false)

(define module-load-fn
  {symbol --> module-desc --> load-fn}
  _ [] -> null-load-fn
  load-fn [[load-fn : F] | _] -> F where (= (arity F) 1)
  load-fn [[load-fn : F] | _] -> (error "Wrong load function ~S.~%" F)
  unload-fn [[unload-fn : F] | _] -> F where (= (arity F) 1)
  unload-fn [[unload-fn : F] | _] -> (error "Wrong unload function ~S.~%" F)
  T [_ | R] -> (module-load-fn T R))

(define null-dump-fn
  {symbol --> symbol --> string --> boolean}
  _ _ _ -> false)

(define module-dump-fn
 {symbol --> (module-desc --> dump-fn)}
  _ [] -> null-dump-fn
  dump-fn [[dump-fn : F] | _] -> F where (= (arity F) 4)
  dump-fn [[dump-fn : F] | _] -> (error "Wrong dump function ~S.~%" F)
  T [_ | R] -> (module-dump-fn T R))

(define module-entry-key
  {entry --> symbol}
  [Key | Def] -> Key)

(define list-modules
  {symbol --> (list symbol)}
  loaded -> (value *loaded-modules*)
  all -> (map module-entry-key (value *modules*))
  _ -> (error "(list-modules loaded) or (list-modules all)~%"))

(define find-module-aux
  {symbol --> (list entry) --> module-desc}
  _ [] -> []
  M [[M | Def] | R] -> Def
  M [_ | R] -> (find-module-aux M R))

(define find-module
  {symbol --> module-desc}
  M -> (find-module-aux M (value *modules*)))

(define set-module-path-if-absent
  {string --> module-desc --> module-desc}
  P D -> (append D [[path : P]]) where (= (module-str path D) "")
  P D -> D)

(define forget-module-manifest
  {symbol --> (list entry) --> (list entry) --> (list entry)}
  M [] Acc -> (set *modules* Acc)
  M [[M | _] | L] Acc -> (forget-module-manifest M L Acc)
  M [X | L] Acc -> (forget-module-manifest M L [X | Acc]))

(define add-module!
  {symbol --> module-desc --> symbol}
  null Def -> (error "Module name is not specified.~%")
  Name Def -> (let D (set-module-path-if-absent (value *home-directory*) Def)
                (do (forget-module-manifest Name (value *modules*) [])
                    (set *modules* [[Name | D] | (value *modules*)])
                    Name)))

(define register-module
  {module-desc --> symbol}
  [] -> (error "Wrong module definition.~%")
  Def -> (add-module! (module-sym name Def) Def))

(define module-known?
  {symbol --> boolean}
  M -> false where (= (find-module M) [])
  _ -> true)

(define in-directory
  {string --> (string --> A) --> (exception --> A) --> A}
  S F E -> (let Pwd (value *home-directory*)
             (trap-error (let Path (cd S)
                              Ret (F Path)
                              Path2 (cd Pwd)
                           Ret)
                         (/. Err (do (cd Pwd)
                                     (E Err))))))

(define manifest-exists?
  {symbol --> string --> boolean}
  M P -> (in-directory (cn P (str M))
                       (/. _ (let P (open file "module.shen" in)
                                  R (close P)
                                true))
                       (/. E false)))

(define load-manifest-file
  {symbol --> string --> boolean}
  M P -> false where (not (manifest-exists? M P))
  M P -> (in-directory (cn P (str M))
                       (/. _ (do (load "module.shen")
                                 (module-known? M)))
                       (/. E (error "~A/module.shen: ~S"
                                    P
                                    (error-to-string E)))))

(define load-manifest
  {symbol --> (list string) --> boolean}
  M [] -> false
  M [P | Path] <- (fail-if (/. X (not X)) (load-manifest-file M P))
  M [P | Path] -> (load-manifest M Path))

(define resolve-deps-aux*
  {(list symbol) --> symbol --> module-desc --> (list symbol)
   --> (list symbol)}
  Acc M [] Deps -> (if (load-manifest M (value *modules-paths*))
                       (resolve-deps-aux* Acc M (find-module M) Deps)
                       (error "Unable to find module ~S~%" M))
  Acc M Desc Deps -> (let D (module-deps Desc)
                       (resolve-deps-aux [M | Acc] (append Deps D))))

(define resolve-deps-aux
  {(list symbol) --> (list symbol) --> (list symbol)}
  Acc [] -> Acc
  Acc [D | Deps] -> (resolve-deps-aux [D | Acc] Deps) where (element? D Acc)
  Acc [D | Deps] -> (resolve-deps-aux* Acc D (find-module D) Deps))

(define resolve-deps
  {(list symbol) --> (list symbol)}
  Deps -> (resolve-deps-aux [] Deps))

(define walk-tree*
  {(list symbol) --> (symbol --> boolean) --> (list symbol) --> boolean
   --> boolean}
  _ _ _ false -> false
  [] _ _ Res -> Res
  [M | Mods] Fn Acc Res -> (walk-tree* Mods Fn Acc Res) where (element? M Acc)
  [M | Mods] Fn Acc Res -> (walk-tree* Mods Fn [M | Acc] (Fn M)))

(define walk-tree
  {(list symbol) --> (symbol --> boolean) --> boolean}
  Mods Fn -> (walk-tree* (resolve-deps Mods) Fn [] true))

(define load-native
  {string --> boolean}
  S -> (error "No native loader is defined yet.")
  _ -> false)

(define load-module-files
  {(list string) --> boolean}
  [] -> true
  [F | Files] -> (do (load F)
                     (load-module-files Files)))

(define load-module*
  {symbol --> load-fn --> (list string) --> boolean}
  _ null-load-fn [] -> false
  M null-load-fn Files -> (load-module-files Files)
  M Fn _ -> (Fn (value *home-directory*)))

(define load-module
  {symbol --> module-desc --> boolean}
  _ [] -> false
  M _ -> true where (module-loaded? M)
  M Desc -> (let F (module-load-fn load-fn Desc)
                 L (module-str-list load Desc)
              (in-directory
                (module-str path Desc)
                (/. _ (if (load-module* M F L)
                          (do (set *loaded-modules*
                                   [M | (value *loaded-modules*)])
                              true)
                          false))
                (/. E (error (error-to-string E))))))

(define use-modules
  {(list symbol) --> boolean}
  M -> (walk-tree M (/. X (load-module X (find-module X)))))

(define dump-native
  {symbol --> symbol --> string --> string --> boolean}
  Lang Impl Dir F -> (error "No native loader is defined yet.")
  _ _ _ _ -> false)

(define dump-module-files
  {symbol --> symbol --> string --> (list string) --> boolean}
  L Im D [] -> true
  L Im D [F | Files] -> (do (let F' (cn (value *home-directory*) F)
                              (in-directory
                                ""
                                (/. _ (dump-native L Im D F'))
                                (/. E (error (error-to-string E)))))
                            (dump-module-files L Im D Files)))

(define dump***
  {symbol --> symbol --> string --> symbol --> dump-fn --> (list string)
   --> (list string) --> boolean}
  _ _ _ _ null-dump-fn [] [] -> false
  Lang Impl Dir M Fn _ _ -> (Fn Lang Impl Dir)
                            where (not (= Fn null-dump-fn))
  Lang Impl Dir M _ [] L-files -> (dump-module-files Lang Impl Dir L-files)
  Lang Impl Dir M _ D-files _ -> (dump-module-files Lang Impl Dir D-files))

(define dump**
  {symbol --> symbol --> string --> symbol --> module-desc --> boolean}
  _ _ _ _ [] -> false
  Lang Impl Dir M Desc -> (let F (module-dump-fn dump-fn Desc)
                               D (module-str-list dump Desc)
                               L (module-str-list load Desc)
                            (in-directory
                              (module-str path Desc)
                              (/. _ (dump*** Lang Impl Dir M F D L))
                              (/. E (error (error-to-string E))))))

(define dump*
  {symbol --> symbol --> string --> symbol --> boolean}
  Lang Impl Dir M -> (dump** Lang Impl Dir M (find-module M)))

(define dump-module
  {symbol --> symbol --> symbol --> string --> boolean}
  M Lang Impl Dir -> (let Dir' (cn (value *home-directory*) Dir)
                       (walk-tree [M] (dump* Lang Impl Dir')))
                     where (module-loaded? M)
  M _ _ _ -> (error "Dump error: module ~S is not loaded.~%" M))

(define forget-module*
  {symbol --> module-desc --> load-fn --> boolean}
  M [] _ -> true
  M _ null-load-fn -> true
  M Desc Fn -> (in-directory (module-str path Desc)
                             Fn
                             (/. E (error (error-to-string E)))))

(define forget-module
  {symbol --> boolean}
  M -> (let D (find-module M)
            F (module-load-fn unload-fn D)
            L (set *loaded-modules* (remove M (value *loaded-modules*)))
            R (forget-module-manifest M (value *modules*) [])
         (forget-module* M D F))
       where (module-loaded? M)
  _ -> true)

(define reload-module
  {symbol --> boolean}
  M -> (do (forget-module M)
           (use-modules [M]))))