/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_WritePAEInBlob
Description         :	Retourne l'objet Un_ScholarshipPmt correspondant au OperID dans le blob du pointeur @pBlob 
								ou le champs texte @vcBlob.
Valeurs de retours  :	Type d’objet traité être dans le blob :
									Un_ScholarshipPmt
										ScholarshipPmtID	INTEGER
										OperID			INTEGER
										ScholarshipID		INTEGER
										CollegeID		INTEGER
										CompanyName		VARCHAR(75)
										ProgramID		INTEGER
										ProgramDesc		VARCHAR(75)
										StudyStart		DATETIME
										ProgramYear		INTEGER
										ProgramLength		INTEGER
										RegistrationProof	BIT
										SchoolReport		BIT
										EligibilityQty		INTEGER
										CaseOfJanuary		BIT
										EligibilityConditionID	CHAR(3)					VARCHAR(10)
								@ReturnValue :
									> 0 : Réussite
									<= 0 : Erreurs.
Note                :	ADX0000984	IA	2006-05-15	Alain Quirion		Création
										2010-01-18	Jean-F. Gauthier	Ajout du champ EligibilityConditionID (table Un_ScholarshipPmt) en retour
										2012-08-01	Pierre-Luc Simard	Ajout de ISNULL pour S.EligibilityConditionID
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_WritePAEInBlob] (
	@OperID INTEGER, -- ID de l’opération de chèque
	@iBlobID INTEGER, -- ID du blob dans lequel on écrit
	@pBlob BINARY(16), -- Pointeur sur le blob
	@vcBlob VARCHAR(8000) OUTPUT, -- Contient le texte des objets à insérer dans le blob
	@iResult INTEGER OUTPUT ) -- Varible résultat
AS
BEGIN
	-- Un_ScholarshipPmt;ScholarshipPmtID;OperID;ScholarshipID;CollegeID;CompanyName;ProgramID;ProgramDesc;StudyStart;ProgramYear;ProgramLength;RegistrationProof;SchoolReport;EligibilityQty;CaseOfJanuary;EligibilityConditionID
	
	-- Traite les PAE
	IF EXISTS (
			SELECT OperID
			FROM Un_ScholarshipPmt
			WHERE OperID = @OperID) AND
		(@iResult > 0)
	BEGIN
		-- Si Il n'y pas assez d'espace disponible dans la variable, on inscrit le contenu de la variable dans le blob et on vide la variable par la suite
		IF LEN(@vcBlob) > 7700
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

		-- Inscrit les données du PAE de l'opération dans le blob
		SELECT 
			@vcBlob = 
				@vcBlob +
				'Un_ScholarshipPmt;'+
				CAST(S.ScholarshipPmtID AS VARCHAR)+';'+
				CAST(@OperID AS VARCHAR)+';'+
				CAST(S.ScholarshipID AS VARCHAR)+';'+
				CAST(S.CollegeID AS VARCHAR)+';'+
				CAST(CY.CompanyName AS VARCHAR)+';'+
				CAST(S.ProgramID AS VARCHAR)+';'+
				CAST(P.ProgramDesc AS VARCHAR)+';'+
				CONVERT(CHAR(10), ISNULL(S.StudyStart,-2), 20)+';'+ --Anciennement, la date de début des études pouvait être NULL ce qui causait un problème (-2 en SQL équivaut à 0 en DELPHI)
				CAST(S.ProgramYear AS VARCHAR)+';'+
				CAST(S.ProgramLength AS VARCHAR)+';'+
				CAST(S.RegistrationProof AS VARCHAR)+';'+
				CAST(S.SchoolReport AS VARCHAR)+';'+
				CAST(S.EligibilityQty AS VARCHAR)+';'+
				CAST(S.CaseOfJanuary AS VARCHAR)+';'+
				CAST(C.EligibilityConditionID AS VARCHAR)+';'+		
				CAST(ISNULL(S.EligibilityConditionID,'') AS VARCHAR)+';'+		-- 2010-01-18 : AJOUT : JFG	
				CHAR(13)+CHAR(10)
		FROM Un_ScholarshipPmt S
		JOIN Un_College C ON C.CollegeID = S.CollegeID
		JOIN Mo_Company CY ON CY.CompanyID = C.CollegeID
		JOIN Un_Program P ON P.ProgramID = S.ProgramID
		WHERE OperID = @OperID
	END

	RETURN @iResult
END
