/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_Def
Description         :	Retourne les paramètres de configuration propre à l'application.
Valeurs de retours  :	Dataset :
									MaxLifeCotisation						Maximum de cotisation à vie pour un bénéficiaire.
									MaxYearCotisation						Maximum de cotisation par année pour un bénéficiaire.
									ScholarshipMode						Mode de traitement du module des bourses. (PMT = mode paiement, QUA = Qualification)
									ScholarshipYear						Année présentement en traitement dans le module des bourses.
									GovernmentBN							Numéro d'enregistrement du promoteur Fondation Universitas à la SCÉÉ.
									LastVerifDate							On ne peut pas ajouter, modifier ou supprimer d'opérations dont la date d'opération est plus petite ou égale à cette date.
									MaxRepRisk								Taux de commission maximum pour que les avances soit remboursé seulement par les commissions de service
									LastDepositMaxInInterest			Maximum d'intérêts clients pour le dernier dépôt.
									YearQtyOfMaxYearCotisation			Maximum d'année après la date de vigueur pour cotiser un groupe d'unités.
									MaxPostInForceDate					Maximum de mois dont la date de vigueur peut précéder la date de signature dans un groupe d'unités.
									MaxSubscribeAmountAjustmentDiff	La valeur absolue d'un ajustement du montant souscrit d'un groupe d'unités (Un_Unit.SubscribeAmountAjustment) ne doit pas dépasser ce maximum.
									RepProjectionTreatmentDate			Date à laquelle à eu lieu la dernière projection de commissions.
									ProjectionCount						Champs de configuration de la prochaine projection.  C'est le nombres traitement à projeter de projections.
									ProjectionType							Champs de configuration de la prochaine projection.  C'est le type de projections. (1 = annuel, 2 semi-annuel, 4 = trimestriel, 12 = mensuel)
									ProjectionOnNextRepTreatment		Champs boolean identifiant si une projection a été commandé pour le prochain traitement de commissions.
									MaxLifeGovernmentGrant				Maximum de subventions que peut obtenir un bénéficiaire à vie.
									MaxYearGovernmentGrant				Maximum de subventions que peut obtenir un bénéficiaire par année.
									MaxFaceAmount							Maximum d'épargnes et de frais non couvert assurable par l'assurance souscripteur.  La somme de tout les montants souscrits - les montants d'épargnes et de frais réels des conventions d'un souscripteur ne doit pas dépasser ce maximum.
									StartDateForIntAfterEstimatedRI	Date à partir de laquelle on génère de l'intérêt sur capital pour les conventions collectives après la date estimée de remboursement intégral.
									MonthNoIntAfterEstimatedRI			Délai en mois avant de génèrer de l'intérêt sur capital pour les conventions collectives après la date estimée de remboursement intégral.
									CESGWaitingDays						Délai administratif en jour pour l'envoi des remboursements de subventions sur les retraits, les résiliations et les effets retournées.
									MonthBeforeNoNASNotice				Après ce nombre de mois à partir de la date de vigueur le système envoi automatiquement un avis de NAS manquant si soit le NAS du souscripteur ou encore le NAS du bénéficiaire est encore manquant.
									BusinessBonusLimit					1	BusinessBonusLimit	int	4	1
									NbBankOpenDays							Nombre de jour ouvrable a ajouté à la date du jour pour un traitement de CPA en date du jour
									DocMaxSizeInMeg						Maximum de la grosseur des fichiers Word généré par la gestion des documents en meg 
									tiCheckNbMonthBefore
									tiCheckNbDayBefore
									iNbMoisAvantRINApresRIO				Nb de mois avant de pouvoir faire des RI sur une individuelle issue d'un RIO

Note                :									2004-06-08	Bruno Lapointe		Migration et développement point 10.27 : Avis de
																							convention sans NAS
											2004-06-11	Bruno Lapointe		Ajout des champs CRQ
								ADX0000158	IA 	2004-08-29	Bruno Lapointe		12.40 - Ajout du champs BusinessBonusLimit
								ADX0000532	IA	2004-10-12	Bruno Lapointe		12.56 - Ajout des champs NbBankOpenDays et
																							NbOpenDaysForNextTreatment. Suppression du champ
																							OpenDaysForBankTransaction
								ADX0000532	IA	2004-10-22	Bruno Lapointe		12.56 - Calcul selon la configuration des CPA, le
																							nombre de jour du prochain traitement.	
																							Suppression du champ NbOpenDaysForNextTreatment
								ADX0000752	IA	2005-07-27	Bruno Lapointe		17.14 - Renommé
								ADX0001179	IA	2006-10-25	Alain Quirion		Modification : Ajout des champs tiCheckNbMonthBefore et tiCheckNbDayBefore
												2008-10-07  Patrick Robitaille	Ajout du champ iNbMoisAvantRINApresRIO	
												2009-06-10	Jean-François Gauthier	Ajout des nouveaux champs de paramètres (vcURLSGRCTableauBord, vcURLSGRCCreationTache, vcURLNoteConsulter, vcURLNoteAjouter)
												2009-12-02	Jean-François Gauthier	Ajout du champ vcURLUniaccesBEC
												2009-12-03	Jean-François Gauthier	ajout du champ vcURLUniaccesChBeneficiaire
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_Def]
AS
BEGIN
	DECLARE 
		@NbBankOpenDays INTEGER

	SELECT 
		@NbBankOpenDays = DaysAfterToTreat+DaysAddForNextTreatment
	FROM Un_AutomaticDepositTreatmentCfg
	WHERE DATEPART(dw, GETDATE()) = TreatmentDay

	SELECT
		MaxLifeCotisation,
		MaxYearCotisation,
		ScholarshipMode,
		ScholarshipYear,
		GovernmentBN,
		LastVerifDate,
		MaxRepRisk,
		LastDepositMaxInInterest,
		YearQtyOfMaxYearCotisation,
		MaxPostInForceDate,
		MaxSubscribeAmountAjustmentDiff,
		RepProjectionTreatmentDate,
		ProjectionCount,
		ProjectionType,
		ProjectionOnNextRepTreatment,
		MaxLifeGovernmentGrant,
		MaxYearGovernmentGrant,
		MaxFaceAmount,
		StartDateForIntAfterEstimatedRI,
		MonthNoIntAfterEstimatedRI,
		CESGWaitingDays,
		MonthBeforeNoNASNotice,
		BusinessBonusLimit,
		NbBankOpenDays = @NbBankOpenDays,
		DocMaxSizeInMeg,
		tiCheckNbMonthBefore,
		tiCheckNbDayBefore,
		iNbMoisAvantRINApresRIO = iNb_Mois_Avant_RIN_Apres_RIO,
		vcURLSGRCTableauBord,
		vcURLSGRCCreationTache,
		vcURLNoteConsulter,
		vcURLNoteAjouter,
		vcURLUniaccesBEC,
		vcURLUniaccesChBeneficiaire
	FROM 
		dbo.Un_Def U, 
		dbo.CRQ_Def C
END
