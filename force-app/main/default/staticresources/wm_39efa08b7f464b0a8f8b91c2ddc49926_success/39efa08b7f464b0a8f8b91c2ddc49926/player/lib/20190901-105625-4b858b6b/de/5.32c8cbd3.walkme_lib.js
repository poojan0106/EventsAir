window.walkMeGermany = true;window._walkmeWebpackJP&&(window._walkmeWebpackJP=window._walkmeWebpackJP||[]).push([[5],{620:function(e,t,s){(function(){var e=s(203),t=(n.prototype.getQuestionAndAnswerTextFromSurvey=function(e,t,n){var s=wmjQuery.grep(e.Questions,function(e){return e.Id==t})[0];switch(s.QuestionType){case this.consts.QUESTION_TYPES.NPS:return this.getAnswerAndQuestionTextForNPS(s,n);case this.consts.QUESTION_TYPES.FreeText:return this.getAnswerAndQuestionTextForFreeText(s);case this.consts.QUESTION_TYPES.RadioButton:case this.consts.QUESTION_TYPES.CheckBox:return this.getAnswerAndQuestionTextForMultipleAnswersQuestion(s,n)}},n.prototype.getAnswerAndQuestionTextForNPS=function(e,t){return{questionText:e.Title,answerText:t}},n.prototype.getAnswerAndQuestionTextForFreeText=function(e){return{questionText:e.Title}},n.prototype.getAnswerAndQuestionTextForMultipleAnswersQuestion=function(e,t){var n=wmjQuery.grep(e.Answers,function(e){return e.Id==t})[0];return{questionText:e.Title,answerText:n.Title}},n);function n(e){this.consts=e}e.register("SurveyQuestionAndAnswerText").asCtor(t).dependencies("Consts")}).call(window)}}]);