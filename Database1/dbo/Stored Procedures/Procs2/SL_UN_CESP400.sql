/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_CESP400
Description         :	Retourne l’information d’un enregistrement 400
Valeurs de retours  :
	Dataset :
		tiCESP400TypeID				TINYINT			Type d’enregistrement 400
		vcTransID						VARCHAR(156)	ID PCEE	 : ID unique de la transaction qui a été envoyé au PCEE.
		dtTransaction					DATETIME			Date envoyé au PCEE pour la transaction.
		dtCESPSendFile					DATETIME			Date d’envoi de la transaction au PCEE
		ConventionNo					VARCHAR(75)		Numéro de convention envoyé au PCEE. 
		iPlanGovRegNumber				INTEGER			Numéro du régime attribué par le gouvernement.
		vcBeneficiarySIN				VARCHAR(75)		NAS du bénéficiaire au moment de la transaction.
		vcSubscriberSINorEN			VARCHAR(75)		NAS du souscripteur. Le PCEE sans sert pour des raisons fiscal.
		bCESPDemand						BIT				Indique au PCEE si le souscripteur a demandé de recevoir de la subvention pour cette transaction.
		fCotisation						MONEY				Montant de cotisation (épargne et frais) que l’on désire subventionner.
		vcPCGFirstName					VARCHAR(35)		Prénom du principal responsable. Utilisé par le PCEE pour déterminer si le bénéficiaire est éligible à la SCEE+.
		vcPCGLastName					VARCHAR(75)		Nom du principal responsable. Utilisé par le PCEE pour déterminer si le bénéficiaire est éligible à la SCEE+.
		vcPCGSINorEN					VARCHAR(15)		NAS du principal responsable s’il s’agit d’une personne, NE s’il s’agit d’une entreprise. Utilisé par le PCEE pour déterminer si le bénéficiaire est éligible à la SCEE+.
		dtStudyStart					DATETIME			Date de début des études du bénéficiaire. Fait parti de la preuve d’inscription qui est obligatoire pour le versement de PAE.
		tiStudyYearWeek				TINYINT			Nombre de semaines d’études par année à l’établissement d’enseignement du bénéficiaire. Fait parti de la preuve d’inscription qui est obligatoire pour le versement de PAE.
		tiProgramLength				TINYINT			Durée du programme : 	Nombre d’année que dure le programme d’études.
		siProgramYear					SMALLINT			Année du programme	 : Année à laquelle est rendu le bénéficiaire dans le programme d’études.
		cCollegeTypeID					CHAR(2)			Type d’établissement d’enseignement : Université, Collège ou Cégep, Établissement privés, Autres. 
		vcCollegeCode					VARCHAR(10)		Code postal de l’établissement d’enseignement.
		fEAP								MONEY				Montant du PAE versée : Montant du chèque du PAE.
		fEAPCESG							MONEY				Montant de SCEE et SCEE + inclus dans le montant du chèque du PAE.
		fEAPCLB							MONEY				Montant de BEC inclus dans le montant du chèque du PAE.
		fPSECotisation					MONEY				Montant de cotisation remboursé au souscripteur dans le retrait EPS.
		fCESG								MONEY				Montant de SCEE à rembourser ou transféré.
		fACESGPart							MONEY				Montant de SCEE+ à rembourser ou transféré.
		fCLB								MONEY				Montant de BEC à rembourser ou transféré.
		iOtherPlanGovRegNumber		INTEGER			Numéro du régime attribué par le gouvernement du régime cédant (19 – Transfert entré) ou du régime cessionnaire (23 – Transfert sortie).
		vcOtherConventionNo			VARCHAR(15)		Numéro du contrat régime cédant (19 – Transfert entré) ou du régime cessionnaire (23 – Transfert sortie).
		tiCESP400WithdrawReasonID 	TINYINT			Raison du remboursement : Retrait de cotisations, Paiement de revenu accumulé (PRA), Résiliation de contrat, Transfert inadmissible, Remplacement d'un bénéficiaire inadmissible, Paiement versé à un établissement d'enseignement, Révocation, Ne répond plus au critère frère et sœur, Décès, Retrait de cotisations excédentaires et Autres.
		vcCESP400WithdrawReason		VARCHAR(200)	Raison du remboursement de subvention (400)
		tiCESPStatus					TINYINT			Statut de l’enregistrement 400. (0 = Normal, 1 = Annulé, 2 = Annulation, 3 = En Erreur)
		dtRead							DATETIME			Date de réception de la réponse.
		fCESG_900						MONEY				Montant de SCEE reçue.
		vcCESP900CESGReason			VARCHAR(200)	Raison pour laquelle la SCEE n’a pas été totalement versée. Si elle est vide c’est qu’elle a toute été versée.
		fACESG_900						MONEY				Montant de SCEE + reçue.
		vcACESP900CESGReason			VARCHAR(200)	Raison pour laquelle la SCEE+ n’a pas été totalement versée. Si elle est vide c’est qu’elle a toute été versée.
		fCLB_900							MONEY				Montant de BEC reçu.
		fCLBFee							MONEY				Montant de frais reçu pour la gestion du BEC.
		siCESP800ErrorID				SMALLINT			Code PCEE de l’erreur (Ex : 7001, 7006, etc.).
		vcErrFieldName					VARCHAR(30)		Champ pointé par le PCEE comme étant la source de l’erreur.
		vcCESP800Error					VARCHAR(200)	Description donnée par le PCEE de l’erreur. Elle pourra être sur plusieurs lignes.


Note                :	ADX0001122	IA	2006-09-20	Bruno Lapointe		Création
										2011-01-31	Frederick Thibault	Ajout du champ fACESGPart pour régler le problème de remboursement SCEE+
***************************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_CESP400] (
	@iCESP400ID INTEGER ) -- ID de l’enregistrement 400
AS
BEGIN
	SELECT
		C4.tiCESP400TypeID, -- Type d’enregistrement 400
		C4.vcTransID, -- ID PCEE : ID unique de la transaction qui a été envoyé au PCEE.
		C4.dtTransaction, -- Date envoyé au PCEE pour la transaction.
		S.dtCESPSendFile, -- Date d’envoi de la transaction au PCEE
		C4.ConventionNo, -- Numéro de convention envoyé au PCEE. 
		C4.iPlanGovRegNumber, -- Numéro du régime attribué par le gouvernement.
		C4.vcBeneficiarySIN, -- NAS du bénéficiaire au moment de la transaction.
		C4.vcSubscriberSINorEN, -- NAS du souscripteur. Le PCEE sans sert pour des raisons fiscal.
		C4.bCESPDemand, -- Indique au PCEE si le souscripteur a demandé de recevoir de la subvention pour cette transaction.
		C4.fCotisation, -- Montant de cotisation (épargne et frais) que l’on désire subventionner.
		C4.vcPCGFirstName, -- Prénom du principal responsable. Utilisé par le PCEE pour déterminer si le bénéficiaire est éligible à la SCEE+.
		C4.vcPCGLastName, -- Nom du principal responsable. Utilisé par le PCEE pour déterminer si le bénéficiaire est éligible à la SCEE+.
		C4.vcPCGSINorEN, -- NAS du principal responsable s’il s’agit d’une personne, NE s’il s’agit d’une entreprise. Utilisé par le PCEE pour déterminer si le bénéficiaire est éligible à la SCEE+.
		C4.dtStudyStart, -- Date de début des études du bénéficiaire. Fait parti de la preuve d’inscription qui est obligatoire pour le versement de PAE.
		C4.tiStudyYearWeek, -- Nombre de semaines d’études par année à l’établissement d’enseignement du bénéficiaire. Fait parti de la preuve d’inscription qui est obligatoire pour le versement de PAE.
		C4.tiProgramLength, -- Durée du programme : 	Nombre d’année que dure le programme d’études.
		C4.siProgramYear, -- Année du programme	 : Année à laquelle est rendu le bénéficiaire dans le programme d’études.
		C4.cCollegeTypeID, -- Type d’établissement d’enseignement : Université, Collège ou Cégep, Établissement privés, Autres. 
		C4.vcCollegeCode, -- Code postal de l’établissement d’enseignement.
		C4.fEAP, -- Montant du PAE versée : Montant du chèque du PAE.
		C4.fEAPCESG, -- Montant de SCEE et SCEE + inclus dans le montant du chèque du PAE.
		C4.fEAPCLB, -- Montant de BEC inclus dans le montant du chèque du PAE.
		C4.fPSECotisation, -- Montant de cotisation remboursé au souscripteur dans le retrait EPS.
		C4.fCESG, -- Montant de SCEE à rembourser ou transféré.
		C4.fACESGPart, -- Montant de SCEE + à rembourser ou transféré.
		C4.fCLB, -- Montant de BEC à rembourser ou transféré.
		C4.iOtherPlanGovRegNumber, -- Numéro du régime attribué par le gouvernement du régime cédant (19 – Transfert entré) ou du régime cessionnaire (23 – Transfert sortie).
		C4.vcOtherConventionNo, -- Numéro du contrat régime cédant (19 – Transfert entré) ou du régime cessionnaire (23 – Transfert sortie).
		C4.tiCESP400WithdrawReasonID, -- Raison du remboursement : Retrait de cotisations, Paiement de revenu accumulé (PRA), Résiliation de contrat, Transfert inadmissible, Remplacement d'un bénéficiaire inadmissible, Paiement versé à un établissement d'enseignement, Révocation, Ne répond plus au critère frère et sœur, Décès, Retrait de cotisations excédentaires et Autres.
		C4WR.vcCESP400WithdrawReason, -- Raison du remboursement de subvention (400)
		tiCESPStatus =
			CASE
				WHEN C4.iCESP800ID IS NOT NULL THEN 3
				WHEN C4.iReversedCESP400ID IS NOT NULL THEN 2
				WHEN S4.iCESP400ID IS NOT NULL THEN 1
			ELSE 0
			END , -- Statut de l’enregistrement 400. (0 = Normal, 1 = Annulé, 2 = Annulation, 3 = En Erreur)
		R.dtRead, -- Date de réception de la réponse.
		fCESG_900 = ISNULL(C9.fCESG,0), -- Montant de SCEE reçue.
		C9R.vcCESP900CESGReason, -- Raison pour laquelle la SCEE n’a pas été totalement versée. Si elle est vide c’est qu’elle a toute été versée.
		fACESG_900 = ISNULL(C9.fACESG,0), -- Montant de SCEE + reçue.
		C9AR.vcCESP900ACESGReason, -- Raison pour laquelle la SCEE+ n’a pas été totalement versée. Si elle est vide c’est qu’elle a toute été versée.
		fCLB_900 = ISNULL(C9.fCLB,0), -- Montant de BEC reçu.
		fCLBFee = ISNULL(C9.fCLBFee,0), -- Montant de frais reçu pour la gestion du BEC.
		C8.siCESP800ErrorID, -- Code PCEE de l’erreur (Ex : 7001, 7006, etc.).
		C8.vcErrFieldName, -- Champ pointé par le PCEE comme étant la source de l’erreur.
		C8R.vcCESP800Error -- Description donnée par le PCEE de l’erreur. Elle pourra être sur plusieurs lignes.
	FROM Un_CESP400 C4
	JOIN Un_Oper O ON O.OperID = C4.OperID
	LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID
	LEFT JOIN Un_CESPSendFile S ON S.iCESPSendFileID = C4.iCESPSendFileID
	LEFT JOIN Un_CESPReceiveFile R ON R.iCESPReceiveFileID = S.iCESPReceiveFileID
	LEFT JOIN Un_CESP900CESGReason C9R ON C9R.cCESP900CESGReasonID = C9.cCESP900CESGReasonID
	LEFT JOIN Un_CESP900ACESGReason C9AR ON C9AR.cCESP900ACESGReasonID = C9.cCESP900ACESGReasonID
	LEFT JOIN Un_CESP800 C8 ON C8.iCESP800ID = C4.iCESP800ID
	LEFT JOIN Un_CESP400 S4 ON S4.iReversedCESP400ID = C4.iCESP400ID
	LEFT JOIN Un_CESP800Error C8R ON C8R.siCESP800ErrorID = C8.siCESP800ErrorID
	LEFT JOIN Un_CESP400WithdrawReason C4WR ON C4WR.tiCESP400WithdrawReasonID = C4.tiCESP400WithdrawReasonID
	WHERE C4.iCESP400ID = @iCESP400ID
END

