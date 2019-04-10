
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_WriteOperInBlob
Description         :	Retourne l'objet Un_Oper correspondant au OperID dans le blob du pointeur @pBlob ou le champs 
								texte @vcBlob.
Valeurs de retours  :	Type d’objet traité être dans le blob :
									Un_Oper
										OperID 					INTEGER
										OperTypeID 				CHAR (3)
										OperDate 				DATETIME	
										ConnectID 				INTEGER
										OperTypeDesc 			VARCHAR (75)
										OperTotal				MONEY
										Status 					TINYINT	
								
							@ReturnValue :
									> 0 : Réussite : ID du blob qui contient les objets
									<= 0 : Erreurs.

Note                :	ADX0000847	IA	2006-03-28	Bruno Lapointe		Création
						ADX00002026	BR	2006-07-18	Mireya Gonthier		Modification	
						ADX0002426	BR	2007-05-22	Alain Quirion		Modification : Un_CESP au lieu de Un_CESP900
*********************************************************************************************************************/
CREATE PROCEDURE dbo.SL_UN_WriteOperInBlob (
	@OperID INTEGER, -- ID de l’opération de chèque
	@iBlobID INTEGER, -- ID du blob dans lequel on écrit
	@pBlob BINARY(16), -- Pointeur sur le blob
	@vcBlob VARCHAR(8000) OUTPUT, -- Contient le texte des objets à insérer dans le blob
	@iResult INTEGER OUTPUT ) -- Varible résultat
AS
BEGIN
	-- Un_Oper;OperID;OperTypeID;OperDate;ConnectID;OperTypeDesc;OperTotal;Status;

	-- Inscrit le détail des objets d'opérations (Un_Oper)
	DECLARE
		-- Variables de l'objet opération
		@OperTypeID CHAR(3),
		@OperDate DATETIME,
		@ConnectID INTEGER,
		@OperTypeDesc VARCHAR(75),
		@Status INTEGER,
		@OperTotal MONEY

	-- Va chercher les données de l'opération (Un_Oper)
	SELECT 
		@OperTypeID = O.OperTypeID,
		@OperDate = O.OperDate,
		@ConnectID = O.ConnectID,
		@OperTypeDesc = OT.OperTypeDesc,
		@Status = 
			CASE
				WHEN CO.OperID IS NOT NULL THEN 1
				WHEN AO.OperID IS NOT NULL THEN 2
			ELSE 0
			END
	FROM Un_Oper O 
	JOIN Un_OperType OT ON OT.OperTypeID = O.OperTypeID
	LEFT JOIN Un_OperCancelation CO ON CO.OperSourceID = O.OperID
	LEFT JOIN Un_OperCancelation AO ON AO.OperID = O.OperID
	WHERE O.OperID = @OperID
			
	-- Inscrit l'opération dans le blob
	-- Un_Oper;OperID;OperTypeID;OperDate;ConnectID;OperTypeDesc;OperTotal;Status;

	-- Calcul le montant total de l'opération
	SET @OperTotal = 0
	SELECT @OperTotal = @OperTotal + ISNULL(SUM(Cotisation+Fee+SubscInsur+BenefInsur+TaxOnInsur),0)
	FROM Un_Cotisation
	WHERE OperID = @OperID
	SELECT @OperTotal = @OperTotal + ISNULL(SUM(ConventionOperAmount),0)
	FROM Un_ConventionOper
	WHERE OperID = @OperID
	SELECT @OperTotal = @OperTotal + ISNULL(SUM(OtherAccountOperAmount),0)
	FROM Un_OtherAccountOper
	WHERE OperID = @OperID
	SELECT @OperTotal = @OperTotal + ISNULL(SUM(fCESG+fACESG+fCLB),0)
	FROM Un_CESP
	WHERE OperID = @OperID
	SELECT @OperTotal = @OperTotal + ISNULL(SUM(PlanOperAmount),0)--- pour le montant provenant d'un plan
	FROM Un_PlanOper
	WHERE OperID = @OperID
	

	-- Si Il n'y pas assez d'espace disponible dans la variable, on inscrit le contenu de la variable dans le blob et on vide la variable par la suite
	IF LEN(@vcBlob) > 7750
	BEGIN
		DECLARE
			@iBlobLength INTEGER

		SELECT @iBlobLength = DATALENGTH(txBlob)
		FROM CRI_Blob
		WHERE iBlobID = @iBlobID

		UPDATETEXT CRI_Blob.txBlob @pBlob @iBlobLength 0 @vcBlob 

		IF @@ERROR <> 0
			SET @iResult = -10

		SET @vcBlob = ''
	END

	SET @vcBlob =
		@vcBlob+
		'Un_Oper;'+
		CAST(@OperID AS VARCHAR)+';'+
		@OperTypeID+';'+
		CONVERT(CHAR(10), @OperDate, 20)+';'+
		CAST(@ConnectID AS VARCHAR)+';'+
		@OperTypeDesc+';'+
		CAST(@OperTotal AS VARCHAR)+';'+
		CAST(@Status AS VARCHAR)+';'+CHAR(13)+CHAR(10)

	RETURN @iResult
END

