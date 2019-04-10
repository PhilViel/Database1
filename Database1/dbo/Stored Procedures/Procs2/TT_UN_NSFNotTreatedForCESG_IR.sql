/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************   */

/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	TT_UN_NSFNotTreatedForCESG_IR
Description         :	Correction d'anomalies : Retourne les NSF qui n’ont pas été traité pour le PCEE. C’est-à-dire 
						pour lesquelles il n’y a pas remboursement de SCEE et de SCEE+ d’effectué.
Valeurs de retours  :	
Note                :	ADX0000496	IA	2005-02-04	Bruno Lapointe		Création
						ADX0001201	IA	2006-11-16	Bruno Lapointe		Adaptation PCEE 4.3 : 12.099.02.07.
						ADX0001243	IA	2007-02-21	Alain Quirion		Modification : ajout des paramètres d'entrées @ObjectType et @iBlobID
                                        2018-01-19  Pierre-Luc Simard   N'est plus utilisé
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_NSFNotTreatedForCESG_IR] (
	@ConnectID INTEGER, -- ID unique de la connection de l'usager
	@ObjectType VARCHAR(75),	-- C’est une chaîne de caractère qui identifie le type des objets. La valeur de ce champ doit être une des suivantes :
									--TUnConvention	L’objet est une convention
									--TUnSubscriber	L’objet est un souscripteur
									--TUnBeneficiary	L’objet est un bénéficiaire
	@iBlobID INTEGER)			-- ID du blob de la table CRI_Blob contenant les ID des objets (ObjectCodeID) séparés par des virgules.
AS
BEGIN
    
    SELECT 1/0
    /*
	DECLARE @ConventionIDs TABLE(
		ConventionID INTEGER PRIMARY KEY)

	IF @ObjectType = 'TUnConvention'
	BEGIN
		INSERT INTO @ConventionIDs
			SELECT DISTINCT iVal
			FROM dbo.FN_CRI_BlobToIntegerTable(@iBlobID)
	END

	DECLARE
		@iCotisationID INTEGER,
		@iIrregularityTypeID INTEGER,
		@iCorrectingCount INTEGER

	-- CotisationID des NSF avec lien
	DECLARE @tCotisationNSFLink TABLE (
		CotisationID INTEGER PRIMARY KEY,
		OperID INTEGER NOT NULL,
		UnitID INTEGER NOT NULL,
		BankReturnSourceCodeID INTEGER NOT NULL )

	INSERT INTO @tCotisationNSFLink
		SELECT
			Ct.CotisationID,
			Ct.OperID,
			Ct.UnitID,
			BRL.BankReturnSourceCodeID
		FROM Un_Cotisation Ct
		JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
		JOIN @ConventionIDs C ON C.ConventionID = U.ConventionID
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		JOIN Mo_BankReturnLink BRL ON BRL.BankReturnCodeID = O.OperID
		WHERE O.OperTypeID = 'NSF'

	DECLARE @tNSFCESGToPaid TABLE (
		iCotisationID INTEGER PRIMARY KEY )

	INSERT INTO @tNSFCESGToPaid		
		SELECT DISTINCT -- NSF avec lien donc la source n'a pas été annulée (remboursée)
			Ct2.CotisationID
		FROM @tCotisationNSFLink Ct
		JOIN Un_Cotisation Ct2 ON Ct2.OperID = Ct.BankReturnSourceCodeID AND Ct2.UnitID = Ct.UnitID
		JOIN Un_CESP400 G4 ON G4.CotisationID = Ct2.CotisationID
		LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
		WHERE	R4.iCESP400ID IS NULL
			AND G4.iReversedCESP400ID IS NULL
			AND G4.iCESP800ID IS NULL

	SET @iCorrectingCount = 0

	SET @iIrregularityTypeID = 0

	SELECT @iIrregularityTypeID = IrregularityTypeID
	FROM Un_IrregularityType
	WHERE CorrectingStoredProcedure = 'TT_UN_NSFNotTreatedForCESG_IR'

	IF @iIrregularityTypeID > 0
	BEGIN 
		SELECT @iCorrectingCount = COUNT(iCotisationID)
		FROM @tNSFCESGToPaid

		IF @iCorrectingCount > 0
		BEGIN		
			DECLARE crNSFCESGToPaid CURSOR FOR
				SELECT iCotisationID
				FROM @tNSFCESGToPaid
			
			OPEN crNSFCESGToPaid
			
			FETCH NEXT FROM crNSFCESGToPaid
			INTO @iCotisationID
			
			WHILE @@FETCH_STATUS = 0
			BEGIN
				EXECUTE IU_UN_ReverseCESP400 0, @iCotisationID, 0
			
				FETCH NEXT FROM crNSFCESGToPaid
				INTO @iCotisationID
			END
			
			CLOSE crNSFCESGToPaid
			DEALLOCATE crNSFCESGToPaid

			IF @@ERROR = 0 
			BEGIN
				INSERT INTO Un_IrregularityTypeCorrection (
					IrregularityTypeID,
					CorrectingStoredProcedure,
					CorrectingCount,
					CorrectingDate )
				VALUES (
					@iIrregularityTypeID,
					'TT_UN_NSFNotTreatedForCESG_IR',
					@iCorrectingCount,
					GETDATE())
			END
		END
	END
    */
END