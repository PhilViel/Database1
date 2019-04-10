/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	DL_UN_LastFileOfAutomaticDeposit
Description         :	Supprime le dernier fichier de CPA.
Valeurs de retours  :	@ReturnValue :
									>0  : La suppression a eu lieu avec succès, ce nombre correspond au BankFileID du fichier 
											supprimé.
									<=0 : Erreur à la suppression :
											-1  : Vous ne pouvez pas travaillez dans cette période.
											-2  : On ne peut pas supprimer le fichier car il y a des CPA de connecté à ces CPA.
											-3  : Erreur à la suppression des liens entres les opérations et le fichier
											-4  : Erreur à la suppression du fichier
											-5  : Erreur à la suppression de l'historique des comptes bancaires
											-6  : Erreur à la suppression des cotisations des CPA générés par le traitement.
											-7  : Erreur à la suppression des opérations sur convention des CPA générés par le traitement.
											-8  : Erreur à la suppression des opérations des CPA générés par le traitement.
											-9  : Erreur à la création du log de la suppression
											-10 : On ne peut pas supprimer le fichier car il y a des CPA dont la demande de subvention a été expédié.
Note                :	ADX0000532	IA	2004-10-12	Bruno Lapointe			Création
								ADX0001659	BR	2005-10-26	Bruno Lapointe			Disabled le trigger pour plus de rapidité.
								ADX0000804	IA	2006-04-06	Bruno Lapointe		Création des enregistrements 400
												2010-10-04	Steve Gouin		Gestion des disable trigger par #DisableTrigger
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[DL_UN_LastFileOfAutomaticDeposit] (
	@ConnectID INTEGER) -- ID unique de l'usager qui fait la suppression
AS
BEGIN

	--ALTER TABLE Un_Cotisation
	--	DISABLE TRIGGER TUn_Cotisation_State

	IF object_id('tempdb..#DisableTrigger') is null
		CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))

	INSERT INTO #DisableTrigger VALUES('TUn_Cotisation_State')				

	-- Déclaration des variables
	DECLARE 
		@ResultID INTEGER,
		@BankFileID INTEGER,
		@BankFileStartDate DATETIME,
		@BankFileEndDate DATETIME,
		@LogDesc VARCHAR(5000)

	-- Remplis les paramètres avec les valeurs du dernier fichier de CPA.
	SELECT 
		@BankFileID = MAX(BankFileID)
	FROM Un_BankFile
	WHERE BankFileEndDate = (SELECT MAX(BankFileEndDate) FROM Un_BankFile)

	SELECT 
		@BankFileStartDate = BankFileStartDate,
		@BankFileEndDate = BankFileEndDate
	FROM Un_BankFile
	WHERE @BankFileID = BankFileID

	-- Vérifie la date de blocage.
	IF EXISTS (
			SELECT LastVerifDate
			FROM Un_Def
			WHERE LastVerifDate >= @BankFileStartDate)
		SET @BankFileID = -1 -- Vous ne pouvez pas travaillez dans cette période.

	-- Vérifie qu'il n'y a pas de NSF sur une opération du fichier
	IF EXISTS (
			SELECT O.OperID
			FROM Un_OperCancelation C
			JOIN Un_Oper O ON O.OperID = C.OperSourceID
			WHERE O.OperTypeID = 'CPA'
			  AND O.OperDate BETWEEN @BankFileStartDate AND @BankFileEndDate
			  AND O.ConnectID = 1)
		SET @BankFileID = -2 -- On ne peut pas supprimer le fichier car il y a des CPA de connecté à ces CPA.

	-- Vérifie qu'il n'y a pas de demande de subvention sur une opération du fichier
	IF EXISTS (
			SELECT O.OperID
			FROM Un_CESP400 G4
			JOIN Un_Oper O ON O.OperID = G4.OperID
			WHERE O.OperTypeID = 'CPA'
				AND O.OperDate BETWEEN @BankFileStartDate AND @BankFileEndDate
				AND O.ConnectID = 1
				AND G4.iCESPSendFileID IS NOT NULL )
		SET @BankFileID = -10 -- On ne peut pas supprimer le fichier car il y a des CPA dont la demande de subvention a été expédié.

	-----------------
	BEGIN TRANSACTION
	-----------------

	-- Suppression des liens entre les opérations de CPA et le fichier de CPA
	IF @BankFileID > 0
	BEGIN
		DELETE 
		FROM Un_OperBankFile
		WHERE @BankFileID = BankFileID
		
		IF @@ERROR <> 0 
			SET @BankFileID = -3 -- Erreur à la suppression des liens entres les opérations et le fichier
	END
	
	-- Suppression du fichier de CPA
	IF @BankFileID > 0
	BEGIN
		DELETE 
		FROM Un_BankFile
		WHERE @BankFileID = BankFileID
		
		IF @@ERROR <> 0 
			SET @BankFileID = -4 -- Erreur à la suppression du fichier
	END

	-- Suppression de l'historique des comptes bancaires
	IF @BankFileID > 0
	BEGIN
		DELETE Un_OperAccountInfo
		FROM Un_OperAccountInfo
		JOIN Un_Oper O ON O.OperID = Un_OperAccountInfo.OperID
		WHERE O.OperTypeID = 'CPA'
		  AND O.OperDate BETWEEN @BankFileStartDate AND @BankFileEndDate
		
		IF @@ERROR <> 0 
			SET @BankFileID = -5 -- Erreur à la suppression de l'historique des comptes bancaires
	END

	-- Suppression des energistrements 400 non-exédiés
	IF @BankFileID > 0
	BEGIN
		DELETE Un_CESP400
		FROM Un_CESP400
		JOIN Un_Cotisation Ct ON Ct.CotisationID = Un_CESP400.CotisationID
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		WHERE O.OperTypeID = 'CPA'
			AND O.OperDate BETWEEN @BankFileStartDate AND @BankFileEndDate
			AND Un_CESP400.iCESPSendFileID IS NULL
		
		IF @@ERROR <> 0 
			SET @BankFileID = -11 -- Erreur à la suppression des energistrements 400 non-exédiés.
	END

	-- Suppression des cotisations des CPA générés par le traitement.
	IF @BankFileID > 0
	BEGIN
		DELETE Un_Cotisation
		FROM Un_Cotisation
		JOIN Un_Oper O ON O.OperID = Un_Cotisation.OperID
		WHERE O.OperTypeID = 'CPA'
			AND O.OperDate BETWEEN @BankFileStartDate AND @BankFileEndDate
			AND O.ConnectID = 1
		
		IF @@ERROR <> 0 
			SET @BankFileID = -6 -- Erreur à la suppression des cotisations des CPA générés par le traitement.
	END

	-- Suppression des opérations sur convention des CPA générés par le traitement.
	IF @BankFileID > 0
	BEGIN
		DELETE Un_ConventionOper
		FROM Un_ConventionOper
		JOIN Un_Oper O ON O.OperID = Un_ConventionOper.OperID
		WHERE O.OperTypeID = 'CPA'
		  AND O.OperDate BETWEEN @BankFileStartDate AND @BankFileEndDate
		  AND O.ConnectID = 1
		
		IF @@ERROR <> 0 
			SET @BankFileID = -7 -- Erreur à la suppression des opérations sur convention des CPA générés par le traitement.
	END

	-- Suppression des opérations des CPA générés par le traitement.
	IF @BankFileID > 0
	BEGIN
		DELETE 
		FROM Un_Oper 
		WHERE OperTypeID = 'CPA'
		  AND OperDate BETWEEN @BankFileStartDate AND @BankFileEndDate
		  AND ConnectID = 1
		
		IF @@ERROR <> 0 
			SET @BankFileID = -8 -- Erreur à la suppression des opérations des CPA générés par le traitement.
	END

	IF @BankFileID > 0
	BEGIN
		-- Crée un log de la suppression
		SET @LogDesc = 
			'BankFileID = '+CAST(@BankFileID AS VARCHAR)+CHAR(13)+CHAR(10)+
			'BankFileStartDate = '+CAST(@BankFileStartDate AS VARCHAR)+CHAR(13)+CHAR(10)+
			'BankFileEndDate = '+CAST(@BankFileEndDate AS VARCHAR)
	
   	EXEC @ResultID = IMo_Log @ConnectID, 'Un_BankFile', @BankFileID, 'D', @LogDesc

		IF @ResultID <= 0 
			SET @BankFileID = -9 -- Erreur à la création du log de la suppression
	END

	IF @BankFileID > 0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------

	--ALTER TABLE Un_Cotisation
	--	ENABLE TRIGGER TUn_Cotisation_State

	Delete #DisableTrigger where vcTriggerName = 'TUn_Cotisation_State'

	RETURN @BankFileID
END
