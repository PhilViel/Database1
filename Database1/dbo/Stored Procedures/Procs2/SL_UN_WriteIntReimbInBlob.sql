/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_WriteIntReimbInBlob
Description         :	Retourne l'objet Un_IntReimb correspondant au OperID dans le blob du pointeur @pBlob 
								ou le champs texte @vcBlob.
Valeurs de retours  :	Type d’objet traité être dans le blob :
									Un_IntReimb
										IntReimbID				INTEGER
										UnitID					INTEGER
										CollegeID				INTEGER
										CompanyName				VARCHAR (75)
										ProgramID				INTEGER
										ProgramDesc				VARCHAR (75)
										IntReimbDate			DATETIME
										StudyStart				DATETIME
										ProgramYear				INTEGER
										ProgramLength			INTEGER
										CESGRenonciation		BIT
										FullRIN					BIT
										FeeRefund				BIT
								@ReturnValue :
									> 0 : Réussite
									<= 0 : Erreurs.
Note                :	ADX0000829	IA	2006-04-03	Bruno Lapointe		Création
										2008-10-16  Patrick Robitaille	Ajout du champ FeeRefund
                                        2018-01-30  Pierre-Luc Simard   Correction pour les FullRIN et FeeRefund NULL
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_WriteIntReimbInBlob] (
	@OperID INTEGER, -- ID de l’opération
	@iBlobID INTEGER, -- ID du blob dans lequel on écrit
	@pBlob BINARY(16), -- Pointeur sur le blob
	@vcBlob VARCHAR(8000) OUTPUT, -- Contient le texte des objets à insérer dans le blob
	@iResult INTEGER OUTPUT ) -- Varible résultat
AS
BEGIN
	-- Un_IntReimb;IntReimbID;UnitID;CollegeID;CompanyName;ProgramID;ProgramDesc;IntReimbDate;StudyStart;ProgramYear;ProgramLength;CESGRenonciation;FullRIN;
	IF EXISTS (
			SELECT IRO.OperID
			FROM Un_IntReimbOper IRO
			JOIN Un_Oper O ON O.OperID = IRO.OperID AND O.OperTypeID = 'RIN'
			WHERE IRO.OperID = @OperID ) AND
		(@iResult > 0)
	BEGIN
		-- Si Il n'y pas assez d'espace disponible dans la variable, on inscrit le contenu de la variable dans le blob et on vide la variable par la suite
		IF LEN(@vcBlob) > 7000
		BEGIN
			DECLARE
				@iBlobLength INTEGER

			SELECT @iBlobLength = DATALENGTH(txBlob)
			FROM CRI_Blob
			WHERE iBlobID = @iBlobID

			UPDATETEXT CRI_Blob.txBlob @pBlob @iBlobLength 0 @vcBlob 

			IF @@ERROR <> 0
				SET @iResult = -11

			SET @vcBlob = ''
		END

		-- Inscrit l'objet de remboursement intégral dans le blob
		-- Un_IntReimb;IntReimbID;UnitID;CollegeID;CompanyName;ProgramID;ProgramDesc;IntReimbDate;StudyStart;ProgramYear;ProgramLength;CESGRenonciation;FullRIN;
		SELECT 
			@vcBlob = 
				@vcBlob +
				'Un_IntReimb;'+
				CAST(IR.IntReimbID AS VARCHAR)+';'+
				CAST(IR.UnitID AS VARCHAR)+';'+
				CAST(ISNULL(IR.CollegeID,0) AS VARCHAR)+';'+
				ISNULL(C.CompanyName,'')+';'+
				CAST(ISNULL(IR.ProgramID,0) AS VARCHAR)+';'+
				ISNULL(P.ProgramDesc,'')+';'+
				CONVERT(CHAR(10), ISNULL(IR.IntReimbDate,0), 20)+';'+
				CONVERT(CHAR(10), ISNULL(IR.StudyStart,0), 20)+';'+
				CAST(IR.ProgramYear AS VARCHAR)+';'+
				CAST(IR.ProgramLength AS VARCHAR)+';'+
				CAST(IR.CESGRenonciation AS VARCHAR)+';'+
				CAST(ISNULL(IR.FullRIN, 0) AS VARCHAR)+';'+
				CAST(ISNULL(IR.FeeRefund, 0) AS VARCHAR)+';'+CHAR(13)+CHAR(10)
		FROM Un_IntReimbOper IRO
		JOIN Un_IntReimb IR ON IR.IntReimbID = IRO.IntReimbID
		LEFT JOIN Un_Program P ON P.ProgramID = IR.ProgramID
		LEFT JOIN Mo_Company C ON C.CompanyID = IR.CollegeID
		WHERE IRO.OperID = @OperID
	END

	RETURN @iResult
END