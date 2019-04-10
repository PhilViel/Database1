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
Nom                 :	TT_UN_IROnColConvWithNoIRDate_IR
Description         :	Correction d'anomalies : Convention collective avec une ou des opérations de type RIN et sans
								date de RI.
Valeurs de retours  :	Dataset de données
Note                :	ADX0000496	IA	2005-02-04	Bruno Lapointe		Création
						ADX0001243	IA	2007-02-21	Alain Quirion		Modification : ajout des paramètres d'entrées @ObjectType et @iBlobID
                                        2018-01-19  Pierre-Luc Simard   N'est plus utilisé
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_IROnColConvWithNoIRDate_IR] (
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
		@iIrregularityTypeCorrection MoID,
		@iIrregularityTypeID MoID,
		@iCorrectingCount MoID

	SET @iCorrectingCount = 0

	SET @iIrregularityTypeID = 0

	SELECT @iIrregularityTypeID = IrregularityTypeID
	FROM Un_IrregularityType
	WHERE CorrectingStoredProcedure = 'TT_Un_IROnColConvWithNoIRDate_IR'

	IF @iIrregularityTypeID > 0
	BEGIN 
		SELECT @iCorrectingCount = COUNT(UnitID)
		FROM (
			SELECT 
				U.UnitID, 
				IntReimbDate = MAX(O.OperDate)
			FROM dbo.Un_Convention C
			JOIN @ConventionIDs C2 ON C2.ConventionID = C.ConventionID
			JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
			JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
			JOIN Un_Oper O ON O.OperID = Ct.OperID
			JOIN Un_Plan P ON P.PlanID = C.PlanID AND (P.PlanTypeID <> 'IND')
			WHERE O.OperTypeID = 'RIN'
				AND U.IntReimbDate IS NULL
			GROUP BY U.UnitID
			) V

		IF @iCorrectingCount > 0
		BEGIN
			UPDATE dbo.Un_Unit 
			SET
				IntReimbDate = V.IntReimbDate
			FROM dbo.Un_Unit 
			JOIN (
				SELECT 
					U.UnitID, 
					IntReimbDate = MAX(O.OperDate)
				FROM dbo.Un_Convention C
				JOIN @ConventionIDs C2 ON C2.ConventionID = C.ConventionID
				JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
				JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
				JOIN Un_Oper O ON O.OperID = Ct.OperID
				JOIN Un_Plan P ON P.PlanID = C.PlanID AND (P.PlanTypeID <> 'IND')
				WHERE O.OperTypeID = 'RIN'
					AND U.IntReimbDate IS NULL
				GROUP BY U.UnitID
				) V ON V.UnitID = Un_Unit.UnitID

			IF @@ERROR = 0 
			BEGIN
				INSERT INTO Un_IrregularityTypeCorrection (
					IrregularityTypeID,
					CorrectingStoredProcedure,
					CorrectingCount,
					CorrectingDate )
				VALUES (
					@iIrregularityTypeID,
					'RUn_IrIROnColConvWithNoIRDate',
					@iCorrectingCount,
					GETDATE())
			END
		END
	END
    */
END