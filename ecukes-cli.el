;;; ecukes-cli.el --- Entry point when running Ecukes from terminal

(require 'f)
(require 's)
(require 'dash)
(require 'commander)

(defvar ecukes-root (f-dirname load-file-name)
  "Path to Ecukes root.")

(add-to-list 'load-path ecukes-root)

(require 'ecukes-core)
(require 'ecukes-load)
(require 'ecukes-new)
(require 'ecukes-print)
(require 'ecukes-project)
(require 'ecukes-run)
(require 'ecukes-stats)



(defvar ecukes-include-tags nil
  "Scenario tags to include.")

(defvar ecukes-exclude-tags nil
  "Scenario tags to exclude.")

(defvar ecukes-cli-with-doc nil
  "If the list-steps command show doc or not.")

(defvar ecukes-cli-with-file nil
  "If the list-steps command show definition file or not.")



(defun ecukes-cli/list-steps ()
  (ecukes-load-step-definitions)
  (ecukes-print-steps ecukes-cli-with-doc ecukes-cli-with-file))

(defun ecukes-cli/with-doc ()
  (setq ecukes-cli-with-doc t))

(defun ecukes-cli/with-file ()
  (setq ecukes-cli-with-file t))

(defun ecukes-cli/debug ()
  (setq debug-on-error t)
  (setq debug-on-entry t)
  (setq ecukes-verbose t))

(defun ecukes-cli/verbose ()
  (setq ecukes-verbose t))

(defun ecukes-cli/tags (tag-string)
  (-each
   (s-split "," tag-string)
   (lambda (tag)
     (if (s-prefix-p "~" tag)
         (!cons (s-chop-prefix "~@" tag) ecukes-exclude-tags)
       (!cons (s-chop-prefix "@" tag) ecukes-include-tags)))))

(defun ecukes-cli/run (&rest args)
  (ecukes-load)
  (let ((feature-files))
    (-each
     args
     (lambda (arg)
       (let ((path (f-expand arg (ecukes-project-path))))
         (if (f-dir? path)
             (-each
              (f-glob "*.feature" path)
              (lambda (feature-file)
                (!cons feature-file feature-files)))
           (!cons path feature-files)))))
    (ecukes-run feature-files)))

(defun ecukes-cli/help ()
  (commander-print-usage)
  (ecukes-quit 0))

(defun ecukes-cli/new ()
  (ecukes-new))



(commander
 (name "ecukes")
 (description "Cucumber for Emacs")

 (default ecukes-cli/run "features")

 (command "list-steps" "Print all available steps defined for this project." ecukes-cli/list-steps)
 (option "--with-doc" "Include docstring when printing steps with 'list-steps'." ecukes-cli/with-doc)
 (option "--with-file" "Include file name when printing steps with 'list-steps'." ecukes-cli/with-file)

 (option "-h, --help" "Display this help message" ecukes-cli/help)
 (option "--verbose" "Show `message' and `print' output" ecukes-cli/verbose)
 (option "--debug" "Run in debug mode (show all output and stacktraces)" ecukes-cli/debug)
 (option "--tags <tag-string>" ("Only execute the scenarios with tags matching TAG_EXPRESSION."
                                "TAG_EXPRESSION Examples: --tags @dev, --tags @dev,~@local"
                                "A tag starting with ~ excluded from the scenarios.") ecukes-cli/tags)
 (option "--script" "Run Ecukes as a script/batch job" ignore)
 (option "--win" "Run Ecukes with full GUI window" ignore)

 (command "new" "Create new Ecukes setup for project" ecukes-cli/new))



(ecukes-quit
 (if (> ecukes-stats-steps-failed 0) 1 0))

;;; ecukes-cli.el ends here
