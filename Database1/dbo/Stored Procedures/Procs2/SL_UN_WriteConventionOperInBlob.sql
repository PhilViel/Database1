/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_WriteConventionOperInBlob
Description         :	Retourne les objets Un_ConventionOper correspondant au OperID dans le blob du pointeur(@pBlob) 
								ou le champs texte(@vcBlob).
Valeurs de retours  :	Type d’objet traité être dans le blob :
									Un_ConventionOper
										ConventionOperTypeID CHAR (3)
										ConventionOperID 		INTEGER
										OperID 					INTEGER
										ConventionID 			INTEGER
										ConventionOperAmount	MONEY
										ConventionNo			VARCHAR (75)
										SubscriberID 			INTEGER
										SubscriberName			VARCHAR (87)
										BeneficiaryName		VARCHAR (87)
							@ReturnValue :
								> 0 : Réussite
								<= 0 : Erreurs.
Note                :	
						ADX0000847	IA	2006-03-28	Bruno Lapointe		Création
						ADX0001183	IA	2006-10-12	Bruno Lapointe		Ajout du SubscriberID
						ADX0002426  BR	2007-05-08	Bruno Lapointe		REtourne seulement la dernière 900
						ADX0002426	BR	2007-05-22	Alain Quirion		Modification : Un_CESP au lieu de Un_CESP900
										2009-12-04  Éric Deshaies		Temporairement, ne pas retourner les codes de l'IQÉÉ pour
																		ne pas faire planter les interfaces de consultation des
																		opérations depuis que l'IQÉÉ et les intérêts de l'IQÉÉ
																		sont dans les conventions.
                                        2017-12-15  Pierre-Luc Simard   Ajustement pour inclure la ristourne (RST) dans la bourse (BRS)
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_WriteConventionOperInBlob] (
	@OperID INTEGER, -- ID de l’opération
	@iBlobID INTEGER, -- ID du blob dans lequel on écrit
	@pBlob BINARY(16), -- Pointeur sur le blob
	@vcBlob VARCHAR(8000) OUTPUT, -- Contient le texte des objets à insérer dans le blob
	@iResult INTEGER OUTPUT ) -- Variable résultat
AS
BEGIN
	-- Boucle : Un_ConventionOper;ConventionOperTypeID;ConventionOperID;OperID;ConventionID;ConventionOperAmount;ConventionNo;SubscriberName;BeneficiaryName;

	DECLARE
		-- Variables de l'objet d'opération de convention
		@ConventionOperID INTEGER,
		@ConventionID INTEGER,
		@ConventionOperTypeID VARCHAR(3),
		@ConventionOperAmount MONEY,
		@ConventionNo VARCHAR(75),
		@SubscriberID INTEGER,
		@SubscriberName VARCHAR(152),
		@BeneficiaryName VARCHAR(152)

	-- Curseur de détail des objets d'opérations sur conventions et subventions (Un_ConventionOper)
	DECLARE crWrite_Un_ConventionOper CURSOR FOR
		SELECT 
			ConventionOperID = MIN(CO.ConventionOperID),
			CO.ConventionID,
			ConventionOperTypeID = CASE WHEN CO.ConventionOperTypeID = 'RST' THEN 'BRS' ELSE CO.ConventionOperTypeID END,
			ConventionOperAmount = SUM(CO.ConventionOperAmount),
			C.ConventionNo,
			C.SubscriberID,
			SubscriberName =
				CASE
					WHEN S.IsCompany = 1 THEN S.LastName
				ELSE S.LastName + ', ' + S.FirstName
				END,
			BeneficiaryName = B.LastName+', '+B.FirstName
		FROM Un_ConventionOper CO
		JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
		JOIN dbo.Mo_Human S ON S.HumanID = C.SubscriberID
		JOIN dbo.Mo_Human B ON B.HumanID = C.BeneficiaryID
        WHERE CO.OperID = @OperID
-- Mesure temporaire IQÉÉ
		    AND CO.ConventionOperTypeID NOT IN ('CBQ','MMQ','MIM','IQI','ICQ','IMQ','IIQ','III')
        GROUP BY 
			CO.ConventionID,
			C.ConventionNo,
            CASE WHEN CO.ConventionOperTypeID = 'RST' THEN 'BRS' ELSE CO.ConventionOperTypeID END,
			C.SubscriberID,
			S.IsCompany,
            S.LastName,
			S.FirstName,
            B.LastName,
            B.FirstName
		---------
		UNION ALL
		---------
		SELECT 
			CE.iCESPID,
			CE.ConventionID,
			ConventionOperTypeID = 'SUB',
			CE.fCESG,
			C.ConventionNo,
			C.SubscriberID,
			SubscriberName = S.LastName+', '+S.FirstName,
			BeneficiaryName = B.LastName+', '+B.FirstName
		FROM Un_CESP CE
		JOIN dbo.Un_Convention C ON C.ConventionID = CE.ConventionID
		JOIN dbo.Mo_Human S ON S.HumanID = C.SubscriberID
		JOIN dbo.Mo_Human B ON B.HumanID = C.BeneficiaryID
		WHERE CE.OperID = @OperID
			AND CE.fCESG <> 0
		---------
		UNION ALL
		---------
		SELECT 
			CE.iCESPID,
			CE.ConventionID,
			ConventionOperTypeID = 'SU+',
			CE.fACESG,
			C.ConventionNo,
			C.SubscriberID,
			SubscriberName = S.LastName+', '+S.FirstName,
			BeneficiaryName = B.LastName+', '+B.FirstName
		FROM Un_CESP CE
		JOIN dbo.Un_Convention C ON C.ConventionID = CE.ConventionID
		JOIN dbo.Mo_Human S ON S.HumanID = C.SubscriberID
		JOIN dbo.Mo_Human B ON B.HumanID = C.BeneficiaryID
		WHERE CE.OperID = @OperID
			AND CE.fACESG <> 0
		---------
		UNION ALL
		---------
		SELECT 
			CE.iCESPID,
			CE.ConventionID,
			ConventionOperTypeID = 'BEC',
			CE.fCLB,
			C.ConventionNo,
			C.SubscriberID,
			SubscriberName = S.LastName+', '+S.FirstName,
			BeneficiaryName = B.LastName+', '+B.FirstName
		FROM Un_CESP CE
		JOIN dbo.Un_Convention C ON C.ConventionID = CE.ConventionID
		JOIN dbo.Mo_Human S ON S.HumanID = C.SubscriberID
		JOIN dbo.Mo_Human B ON B.HumanID = C.BeneficiaryID
		WHERE CE.OperID = @OperID
			AND CE.fCLB <> 0

	-- Ouvre le curseur
	OPEN crWrite_Un_ConventionOper

	-- Va chercher la première opération sur convention
	FETCH NEXT FROM crWrite_Un_ConventionOper
	INTO
		@ConventionOperID,
		@ConventionID,
		@ConventionOperTypeID,
		@ConventionOperAmount,
		@ConventionNo,
		@SubscriberID,
		@SubscriberName,
		@BeneficiaryName

	WHILE (@@FETCH_STATUS = 0)
	  AND (@iResult > 0)
	BEGIN
		-- S'il n'y pas assez d'espace disponible dans la variable, on inscrit le contenu de la variable dans le blob et on vide la variable par la suite
		IF LEN(@vcBlob) > 7500
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

		-- Inscrit l'opération sur convention dans le blob
		-- Un_ConventionOper;ConventionOperTypeID;ConventionOperID;OperID;ConventionID;ConventionOperAmount;ConventionNo;SubscriberID;SubscriberName;BeneficiaryName;
		SET @vcBlob =
			@vcBlob+
			'Un_ConventionOper;'+
			@ConventionOperTypeID+';'+
			CAST(@ConventionOperID AS VARCHAR)+';'+
			CAST(@OperID AS VARCHAR)+';'+
			CAST(@ConventionID AS VARCHAR)+';'+
			CAST(@ConventionOperAmount AS VARCHAR)+';'+
			@ConventionNo+';'+
			CAST(@SubscriberID AS VARCHAR)+';'+
			@SubscriberName+';'+
			@BeneficiaryName+';'+
			CHAR(13)+CHAR(10)

		-- Passe à la prochaine opération sur convention
		FETCH NEXT FROM crWrite_Un_ConventionOper
		INTO
			@ConventionOperID,
			@ConventionID,
			@ConventionOperTypeID,
			@ConventionOperAmount,
			@ConventionNo,
			@SubscriberID,
			@SubscriberName,
			@BeneficiaryName
	END -- WHILE (@@FETCH_STATUS = 0) de crWrite_Un_ConventionOper
	
	-- Détruit le curseur d'opérations sur conventions
	CLOSE crWrite_Un_ConventionOper
	DEALLOCATE crWrite_Un_ConventionOper

	RETURN @iResult
END