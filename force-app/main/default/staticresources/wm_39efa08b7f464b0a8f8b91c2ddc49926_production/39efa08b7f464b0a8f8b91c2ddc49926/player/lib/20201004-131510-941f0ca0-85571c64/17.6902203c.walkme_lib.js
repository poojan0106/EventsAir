!function(){window;(window._walkmeWebpackJP=window._walkmeWebpackJP||[]).push([[17],{1161:function(e,t,n){"use strict";n.r(t),n.d(t,"SurveyQuestionAndAnswerText",function(){return r});var s=n(41),r=(o.prototype.getQuestionAndAnswerTextFromSurvey=function(e,t,n){var s=wmjQuery.grep(e.Questions,function(e){return e.Id==t})[0];switch(s.QuestionType){case this.consts.QUESTION_TYPES.NPS:return this.getAnswerAndQuestionTextForNPS(s,n);case this.consts.QUESTION_TYPES.FreeText:return this.getAnswerAndQuestionTextForFreeText(s);case this.consts.QUESTION_TYPES.RadioButton:case this.consts.QUESTION_TYPES.CheckBox:return this.getAnswerAndQuestionTextForMultipleAnswersQuestion(s,n)}},o.prototype.getAnswerAndQuestionTextForNPS=function(e,t){return{questionText:e.Title,answerText:t}},o.prototype.getAnswerAndQuestionTextForFreeText=function(e){return{questionText:e.Title}},o.prototype.getAnswerAndQuestionTextForMultipleAnswersQuestion=function(e,t){var n=wmjQuery.grep(e.Answers,function(e){return e.Id==t})[0];return{questionText:e.Title,answerText:n.Title}},o);function o(e){this.consts=e}s.register("SurveyQuestionAndAnswerText").asCtor(r).dependencies("Consts")}}])}();